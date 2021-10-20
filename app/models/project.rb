include DslError
class Project < ApplicationRecord
  include WitHelper

  has_many :user_projects, dependent: :destroy
  has_many :users, through: :user_projects
  has_many :variables, dependent: :destroy
  has_many :contexts, dependent: :destroy
  has_many :dialogues, dependent: :destroy
  has_many :problems, dependent: :destroy

  has_many :children_arcs, through: :dialogues
  has_many :parameters, through: :children_arcs

  after_create :fallback_dialogue

  belongs_to :prod_project, foreign_key: :prod_project_id, class_name: "Project", dependent: :destroy, optional: true
  belongs_to :tmp_project, foreign_key: :tmp_project_id, class_name: "Project", dependent: :destroy, optional: true

  def has_user(user)
    self.user_projects.where(user: user).exists?
  end

  def get_user_project(user)
    user_project = self.user_projects.where(user: user).first
    user_project = self.user_projects.create!(user: user, role: 'subscriber') if !user_project && self.prod_project_id.present?
    return user_project
  end

  def is_user_admin_or_author(user)
    user_project = self.user_projects.where(user: user, role: [UserProject.roles[:admin], UserProject.roles[:author]])
    user_project.length > 0
  end

  def export_contexts
    tmp_contexts = {}
    self.contexts.each do |context|
      tmp_contexts[context.id] = context.export
    end
    return tmp_contexts
  end

  def delete_old_user_sessions
    self.user_projects.each do |user_project|
      session = user_project.user_chatbot_session
      if (session && session.updated_at < Time.now - 3.hours)
        user_project.user_chatbot_session.destroy
      end
    end
    if self.prod_project
      UserChatbotSession.where(context_id: self.prod_project.context_ids).each do |session|
        session.destroy if session.updated_at < Time.now - 3.hours
      end
    end
  end

  def delete_tmp_project
    return unless self.tmp_project
    tmp_project = self.tmp_project
    tmp_project.delete_old_user_sessions
    if UserChatbotSession.where(context_id: tmp_project.context_ids).empty?
      tmp_project.destroy!
      self.tmp_project_id = nil
      self.save!
    end
  end

  def export_dialogues
    tmp_dialogues = {}
    self.dialogues.each do |dialogue|
      tmp_dialogues[dialogue.id] = dialogue.export
    end
    tmp_arcs = []
    arcs_ids = self.dialogues.joins(:parents_arcs).select("arcs.id")
    arcs = Arc.where(id: arcs_ids)
    arcs.each do |arc|
      tmp_arcs << arc.export
    end
    return {dialogues: tmp_dialogues, arcs: tmp_arcs}
  end

  def import_contexts(contexts_data)
    contexts_data.map {|i, c|
      c[:new_id] = self.contexts.create!(c).id
    }
  end

  def import_dialogues(contexts_data, dialogues_and_arcs_data)
    dialogues = {}
    dialogues_data = dialogues_and_arcs_data[:dialogues].map{|old_id, dialogue| 
      dialogue[:context_id] = contexts_data[dialogue[:context_id].to_s.to_sym][:new_id] if dialogue[:context_id]
      dialogue.except(:variables, :responses, :intent)
    }
    new_dialogues = self.dialogues.create!(dialogues_data)
    intents = []
    dialogues_and_arcs_data[:dialogues].each_with_index do |(old_id, dialogue), i|
      tmp = {
        variables: dialogue[:variables],
        responses: dialogue[:responses],
        intent: dialogue[:intent]
      }
      dialogues[old_id] = {
        new_dialogue: new_dialogues[i]
      }
      new_dialogues[i].import(tmp)
      intents << {dialogue_id: new_dialogues[i].id, value: dialogue[:intent][:value]} if dialogue[:intent]
    end
    Intent.create!(intents)
    arcs_data = dialogues_and_arcs_data[:arcs].map do |arc|
      parent_id = dialogues[arc[:parent_id].to_s.to_sym].nil? ? nil : dialogues[arc[:parent_id].to_s.to_sym][:new_dialogue].id
      child_id = dialogues[arc[:child_id].to_s.to_sym][:new_dialogue].id
      { parent_id: parent_id, child_id: child_id, go_next: arc[:go_next], is_and: arc[:is_and] }
    end
    new_arcs = Arc.create!(arcs_data)
    dialogues_and_arcs_data[:arcs].each_with_index do |arc, i|
      new_arcs[i].import(arc[:conditions], dialogues_and_arcs_data)
    end
  end

  def import_dialogues_dsl(dialogues, arcs)
    dialogues.each do |dialogue_name, dialogue|
      tmp = dialogue.deep_dup
      p "imprting dialogue name #{dialogue_name}"
      dialogues[dialogue_name][:new_dialogue] = self.dialogues.create!({name: dialogue_name}.merge(tmp.except(:options, :variables, :responses , :Intent_value)))
      Intent.create!(dialogue_id: dialogues[dialogue_name][:new_dialogue].id , value: dialogue[:Intent_value]) unless dialogue[:Intent_value].nil?
      dialogues[dialogue_name][:children] = arcs[dialogue_name]
    end

    dialogues.each do |_, dialogue|
      dialogue[:children].each do |child_name, arc_data|
        if dialogues[child_name] == nil
          if !self.dialogues.find_by_name(child_name) # not in dialogues created before import either
            lhs = arc_data[:conditions][0] ? arc_data[:conditions][0][:variable_name] : 'true'
            rhs = arc_data[:conditions][0][:parameter] && arc_data[:conditions][0][:parameter][:value]
            expected_wrong_line = "[C:#{child_name}]#{lhs}"
            expected_wrong_line += "=#{rhs}" if rhs
            line_number = get_error_line(@lines_without_comments_arr, expected_wrong_line)
            raise "undefined dialogue '#{child_name}' mentioned in DSL file line #{line_number}: #{expected_wrong_line}"
          end
        end
        dialogue[:children][child_name][:id] = dialogues[child_name] ? dialogues[child_name][:new_dialogue].id : self.dialogues.find_by_name(child_name).id
      end
      dialogue[:new_dialogue].import_dsl(dialogue, @lines_without_comments_arr)
    end
  end

  def connect_facebook_page
    if self.facebook_page_access_token && self.facebook_page_id
      begin
        url = "https://graph.facebook.com/v6.0/#{self.facebook_page_id}/subscribed_apps"
        form = {'subscribed_fields' => "messages, messaging_postbacks", 'access_token' => self.facebook_page_access_token}
        RestClient.post(url, form)

        url = "https://graph.facebook.com/v6.0/me/messenger_profile?access_token=#{self.facebook_page_access_token}"
        body = {'whitelisted_domains': ['https://beta.optobot.ai/']}
        RestClient.post(url, body)
      rescue => e
        p e&.message
        p e&.response&.body
      end
    end
  end

  def fallback_dialogue
    new_dilog = Dialogue.create!(project_id: self.id , name: "do_not_understand", context_id: nil, actions: nil, tag: "fallback/do_not_understand")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, I don't understand! , Say that again!"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "technical_problem", context_id: nil, actions: nil, tag: "fallback/technical_problem")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, it's a technical problem"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "no_route_matching", context_id: nil, actions: nil, tag: "fallback/no_route_matching")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, no route matching"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "fallback_limit_exceeded", context_id: nil, actions: nil, tag: "fallback/fallback_limit_exceeded")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, fallback limit exceeded"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "not_allowed_value", context_id: nil, actions: nil, tag: "fallback/not_allowed_value")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, not allowed value"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "provided_data_missing", context_id: nil, actions: nil, tag: "fallback/provided_data_missing")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, provided data missing"}, content_type:0)


    new_dilog = Dialogue.create!(project_id: self.id , name: "warning", context_id: nil, actions: nil, tag: "fallback/warning")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "warning"}, content_type:0)

    new_dilog = Dialogue.create!(project_id: self.id , name: "invalid_number", context_id: nil, actions: nil, tag: "fallback/invalid_number")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "please enter a valid number!"}, content_type:0)
  end

  def parse_nlp_file_and_train_wit(file, language)
    file = file.force_encoding('utf-8')
    lines = file.strip.split("\n")
    token = self.nlp_engine[language]
    understanding = {}
    lines.each do |line|
      if ['[I:', '[E:'].include? line[0..2]
        understanding = {}
        value = line.strip.slice(3..-2).gsub(/\s+/, '_')
        understanding[line[1] == 'E' ? :entity : :intent] = value
      elsif line.first.present?
        train_wit_by_samples(line, understanding, token)
      end
    end
    p "Training Done.".to_json
  end

  def get_response_content(res)
    response_types = ["response", "hint", "supplementary", "title", "note", "icon", "button", "alt", "receipt"]
    result = res.gsub(/\s+/,' ').match(/(?:\((#{response_types.join('|')})\))?(.+)/)
    response_type = result[1] || "response"
    response_content = result[2]
    content = response_content
    content_type = 0
    content_type, content = response_content.strip.split('@') if content.include? "@"
    content_type = 1 if content_type == "image"
    content_type = 2 if content_type == "video"
    return response_type, content, content_type
  end

  def get_response(res, language, order=1)
    response_type, content, content_type = get_response_content(res)
    return {order: order, response_type: response_type , response_contents: [{content: {language => content}, content_type: content_type}]}
  end

  def get_all_responses(data, i, language, is_variable=false)
    responses_arr = []
    appended_contents = ['card_image', 'sub_title', 'button_type', 'button_text', 'button_url',
                         'list_headers', 'button_payload', 'order_number', 'currency', 'payment_method',
                         'total_cost', 'element', 'quantity', 'price', 'image_url']
    min = max = nil
    actions = []

    tmp_arr = data.strip.split("\n")
    tmp_arr.each_with_index do |res, index|
      #parses range or action
      result = res.gsub(/\s+/,'').match(/(?:\((?:range|action)\))(.+)/)
      if result && is_variable
        min, max = result[1].split('-', 2)
      elsif result && !is_variable
        action = result[1].match(/(.+)\((.*)\)/)
        actions.push({function: action[1], arguments: action[2].split(',')})
      else
        response_type, content, content_type = get_response_content(res)
        content.gsub!("\\n", "\n")
        if response_type == "alt" || appended_contents.any?(content_type) ||
            (content_type == "list_template" && responses_arr.length > 0 && responses_arr.last[:response_contents].first[:content_type] == 'list_url')
          raise "Alternative response cannot be the first response in DSL file line #{(i+1)/2}" if responses_arr.length == 0
          responses_arr.last[:response_contents].push({content: {language => content}, content_type: content_type})
        else
          responses_arr.push ( get_response(res, language, index+1) )
        end
      end
    end
    return responses_arr, min, max, actions
  end

  def get_variable_information(tmp)
    variable_name, entity_type, storage_type, save_text = tmp.gsub(/\s+/,'_').split(':')
    if entity_type != nil and storage_type.nil? and (entity_type =="normal" || entity_type == "timeseries" || entity_type == "in_session" || entity_type == "in_cache" || entity_type == "timeseries_in_cache"  )
      storage_type = entity_type
      entity_type = nil
    end

    if save_text.nil? and entity_type == "save_text"
      save_text = entity_type
      entity_type = nil
    end

    if save_text.nil? and storage_type == "save_text"
      save_text = storage_type
      storage_type = nil
    end

    storage_type = "normal" if storage_type.nil?
    if storage_type == "timeseries"
      expire_after = storage_type.match?(/\((.+)\)/) ? storage_type.match(/\((.+)\)/)[1].to_i : 5
      storage_type = "timeseries"
    end
    save_text = save_text == nil ? false : true

    return variable_name, entity_type, storage_type, expire_after, save_text
  end

  def get_arc_information(variable_options, condition, language, wit_token, parameter_values)
    arc = nil
    if condition[1].present?
      if variable_options.length == 0
        sub_condition = condition[1].gsub(/\s/, '')
        if (sub_condition =~ /^\[\d*-\d*\]$/) != nil
          tmp = sub_condition.slice(1...-1).split('-')
          arc = {variable_name: condition[0], parameter: {min: tmp[0], max: tmp[1]}}
        else
          arc = {variable_name: condition[0], parameter: {value: condition[1]}}
        end
      else
        intent_name = normalize_for_wit(condition[1])
        train_wit_by_samples(condition[1].strip, { intent: intent_name }, wit_token) unless parameter_values.include?(intent_name)
        arc = {variable_name: condition[0], option: {response: get_response(condition[1].strip, language) }, parameter: {value: intent_name}}
      end
    else
      arc = {variable_name: condition[0]}
    end
    return arc
  end

  def import_context_dialogues_data (file , context_id , language)
    parameter_values = self.parameters.where("conditions.option_id is not null").pluck(:value)
    self.user_projects.each{|up| up.user_chatbot_session&.destroy!}
    if context_id && context_id.to_i != -1
      raise "Invalid Context" unless Context.find_by(id: context_id)
      raise "Invalid Context" if Context.find_by(id: context_id).project_id != self.id
      Context.find_by(id: context_id).dialogues.destroy_all_immediately
    elsif context_id && context_id.to_i == -1
      newcontext = Context.find_or_create_by(project_id: self.id, name: "first_context")
      self.dialogues.where(tag: nil, context_id: newcontext.id).destroy_all_immediately
      context_id = newcontext.id
    elsif context_id.nil?
      self.dialogues.where(context_id: nil, tag: nil).destroy_all_immediately
    end

    file = file.force_encoding("utf-8")

    @lines_without_comments_arr =[]
    file.each_line do |line|
      unless line.start_with?("#")
        @lines_without_comments_arr.push(line)
      end
    end
    file = @lines_without_comments_arr.join("")
    arr = file.strip.split(%r{(\[\w+:?\w*:?[\w\s]*:?\w*\])})
    dialogues = {}
    arcs = {}
    arcs.default = {}
    prev_dialogue = nil
    prev_variable = nil
    form_node = nil
    start_index = 0
    start_index = 1 if arr[0].empty?
    (start_index...arr.length).step(2).each do |i|
      if arr[i][1].upcase == 'N'
        # dialogue node
        responses_arr, _, _, actions = get_all_responses(arr[i+1], i, language)
        tmp = arr[i].strip.slice(3..-2).gsub(/\s+/,'_')
        dialogue_name, intent_value = tmp.gsub(/\s+/,'_').split(':')
        if form_node || intent_value == 'form_node'
          form_node = true
        end
        dialogues[dialogue_name] = {
          context_id: context_id,
          Intent_value: intent_value,
          form_node: form_node,
          options: [],
          variables: {},
          actions: actions,
          responses: responses_arr
        }
        prev_dialogue = dialogue_name
        prev_variable = nil
        arcs[prev_dialogue] = {}

      elsif arr[i][1].upcase == 'P'
        responses_arr, = get_all_responses(arr[i+1], i, language)
        MessengerHelper.persistent_menu(self.facebook_page_access_token, responses_arr)
      elsif arr[i][1].upcase == 'O'
        responses_arr, = get_all_responses(arr[i+1], i, language)
        raise "Option can't have more than one response in DSL file line #{(i+1)/2}. Option defined as #{arr[i+1]}" if responses_arr.length > 1
        if prev_variable and prev_dialogue
          dialogues[prev_dialogue][:variables][prev_variable][:options].push({response: responses_arr.first})
        elsif prev_dialogue
          dialogues[prev_dialogue][:options].push({response: responses_arr.first })
        else
          raise "Option must come after a dialogue [N:..] or variable [V:..] in DSL file line #{(i+1)/2}"
        end

      elsif arr[i][1].upcase == 'V'
        responses_arr, min, max, = get_all_responses(arr[i+1], i, language, true)
        tmp = arr[i].strip.slice(3..-2)
        variable_name, entity_type, storage_type, expire_after, save_text = get_variable_information(tmp)

        dialogues[prev_dialogue][:variables][variable_name] = {
          entity: entity_type,
          options: [],
          storage_type: storage_type,
          expire_after: expire_after,
          source: "collected",
          responses: responses_arr,
          allowed_range: { min: min, max: max },
          save_text: save_text
        }

        prev_variable = variable_name

      elsif arr[i][1].upcase == 'F'
        tmp = arr[i].strip.slice(3..-2)
        variable_name, entity_type, storage_type, expire_after, _ = get_variable_information(tmp)

        tmp_arr = arr[i+1].strip.split("\n")

        fetched_info_arr = tmp_arr[0].gsub(/\s+/,'')
        if fetched_info_arr.upcase.starts_with?('GET') || fetched_info_arr.upcase.starts_with?('POST')
          fetched_info_arr = fetched_info_arr.split(',')
          headers = {}
          body = nil
          tmp_arr[1...].each{ |res|
            result = res.gsub(/\s+/,' ').match(/(\(.+\))?(.+)/)
            if result[1] == "(header)"
              key, value = result[2].split(':')
              headers[key] = value
            elsif result[1] == "(body)"
              body = result[2]
            end
          }
          fetch_info = { :url => fetched_info_arr[1], :method_type => fetched_info_arr[0].downcase ,
            :body => body, :headers => headers, :key => fetched_info_arr[2] }
        else
          fetched_info_arr = fetched_info_arr.match(/(.+)\((.+)\)/)
          raise "error parsing fetched variable definition '#{variable_name}' in DSL file line #{(i+1)/2}" if fetched_info_arr.nil?
          fetch_info = { :function => fetched_info_arr[1], :arguments => fetched_info_arr[2].split(',') }
        end

        dialogues[prev_dialogue][:variables][variable_name] = {
          entity: entity_type,
          options: [],
          storage_type: storage_type,
          expire_after: expire_after,
          source: "fetched",
          responses: [],
          fetch_info: fetch_info
        }
        prev_variable = variable_name

      elsif arr[i][1].upcase == 'C'
        child_name = arr[i].strip.slice(3..-2).gsub(/\s+/,'_')
        conditions = []
        arr[i+1].split('&').each {|x| conditions.push x.split('=')}
        arcs[prev_dialogue][child_name] = {}
        arcs[prev_dialogue][child_name][:conditions] = []

        conditions.each do |condition|
          found =false
          wit_token = self.nlp_engine[language]
          condition[0].strip!
          next if condition[0].downcase == 'true'
          if condition[0].downcase == 'false'
            arcs[prev_dialogue][child_name] = {go_next: false}
            next
          end
          condition[1].strip!  if condition[1].present?
          dialogues.each do |d_name , d_body|
            if !found && d_body[:variables] && d_body[:variables][condition[0]]
              arc = get_arc_information(d_body[:variables][condition[0]][:options], condition, language, wit_token, parameter_values)
              arcs[prev_dialogue][child_name][:conditions].push(arc)
              found =true
            end
          end

          if !found # search in other project variables (created before import)
            self.variables.each do |v|
              if v.name == condition[0] and !found
                arc = get_arc_information(v.options, condition, language, wit_token, parameter_values)
                arcs[prev_dialogue][child_name][:conditions].push(arc)
                found =true
              end
            end
          end
        end
      else
        raise "Format error in line #{(i+1)/2}" and return
      end
    end

    ActiveRecord::Base.transaction do
      self.import_dialogues_dsl(dialogues, arcs)
    end

    dialogues
  end

end
