include DslError
class Project < ApplicationRecord
  has_many :user_projects, dependent: :destroy
  has_many :users, through: :user_projects
  has_many :variables, dependent: :destroy
  has_many :contexts, dependent: :destroy
  has_many :dialogues, dependent: :destroy
  has_many :problems, dependent: :destroy
  
  after_create :fallback_dialogue
  
  has_one :prod_project, foreign_key: :test_project_id, class_name: "Project", dependent: :destroy
  
  def has_user(user)
    self.user_projects.where(user: user).exists?
  end
  
  def get_user_project(user)
    user_project = self.user_projects.where(user: user).first
    user_project = self.user_projects.create!(user: user, role: 'subscriber') if !user_project && self.test_project_id.present?
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
    dialogues_and_arcs_data[:dialogues].each do |old_id, dialogue|
      tmp = {
        variables: dialogue[:variables],
        responses: dialogue[:responses],
        intent: dialogue[:intent]
      }
      dialogue[:context_id] = contexts_data[dialogue[:context_id].to_s.to_sym][:new_id] if dialogue[:context_id]
      new_dialogue = self.dialogues.create!(dialogue.except(:variables, :responses, :intent))
      dialogues[old_id] = {
        new_dialogue: new_dialogue
      }
      new_dialogue.import(tmp)
      Intent.create!(dialogue_id: new_dialogue.id, value: dialogue[:intent][:value]) if dialogue[:intent]
    end
    dialogues_and_arcs_data[:arcs].each do |arc|
      parent_id = dialogues[arc[:parent_id].to_s.to_sym].nil? ? nil : dialogues[arc[:parent_id].to_s.to_sym][:new_dialogue].id
      child_id = dialogues[arc[:child_id].to_s.to_sym][:new_dialogue].id
      Arc.create!(parent_id: parent_id, child_id: child_id).import(arc[:conditions], dialogues_and_arcs_data)
      p "pass"
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
            raise "undefined dailogue '#{child_name}' mentioned in DSL file line #{line_number}" 
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
    new_dilog = Dialogue.create!(project_id: self.id , name: "do_not_understand", context_id: nil, action: nil, tag: "fallback/do_not_understand")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, I don't understand! , Say that again!"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "technical_problem", context_id: nil, action: nil, tag: "fallback/technical_problem")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, it's a technical problem"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "no_route_matching", context_id: nil, action: nil, tag: "fallback/no_route_matching")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, no route matching"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "fallback_limit_exeeded", context_id: nil, action: nil, tag: "fallback/fallback_limit_exeeded")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, fallback limit exeeded"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "not_allowed_value", context_id: nil, action: nil, tag: "fallback/not_allowed_value")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, not allowed value"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "provided_data_missing", context_id: nil, action: nil, tag: "fallback/provided_data_missing")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Sorry, provided data missing"}, content_type:0)
    
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "warning", context_id: nil, action: nil, tag: "fallback/warning")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "warning"}, content_type:0)
    
    new_dilog = Dialogue.create!(project_id: self.id , name: "invalid_number", context_id: nil, action: nil, tag: "fallback/invalid_number")
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "please enter a valid number!"}, content_type:0)
  end
  
  
  def training_wit(file , lang)
    file = file.force_encoding("utf-8")
    arr = file.strip.split("\n")
    intent_value = nil
    entity_value = nil
    
    (0...arr.length).each do |i|
      if arr[i][0]=='[' and arr[i][1]=='I'
        intent_value = arr[i].slice(3..-2).gsub(/\s+/,'_')
        entity_value = nil
      elsif arr[i][0]=='[' and arr[i][1]=='E'
        entity_value = arr[i].slice(3..-2).gsub(/\s+/,'_')
        intent_value = nil
      elsif arr[i][0] != nil
        train_text(arr[i], intent_value,entity = entity_value , language = lang )
      end
    end
    p "Training Done.".to_json
  end
  
  
  def train_text(text, intent_value, entity, language="en")
    entity = "intent" if entity == nil
    p " in train_text given text = #{text}  and intent_value = #{intent_value}  and entity = #{entity}  and language =  #{language} -----------------"
    uri = URI.parse("https://api.wit.ai/samples?v=20170307")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    wit_server_access_token = self.nlp_engine[language]
    request["Authorization"] = "Bearer "+ wit_server_access_token
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    entity = entity == "intent" ? "intent" : entity
    value = entity == "intent" ? intent_value : text
    request.body = JSON.dump([{
      "text" => text ,
      "entities" => [{
          "entity" => entity,
          "value" => value
        }]}])

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end
          
  def get_response_content(res)
    result = res.gsub(/\s+/,' ').match(/(?:\((response|hint|supplementary|title|note|icon|button|alt)\))?(.+)/)
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
    appended_contents = ['title', 'sub_title', 'button_type', 'button_title', 'button_payload', 'list_headers']
    min = max = nil
    tmp_arr = data.strip.split("\n")
    tmp_arr.each_with_index{ |res, index|
      result = res.gsub(/\s+/,'').match(/(?:\(range\))(.+)/)
      if result && is_variable
        min, max = result[1].split('-', 2)
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
    }
    return responses_arr, min, max
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

  def get_arc_information(variable_options, condition, language)
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
        intent_name = condition[1]
        train_text(condition[1].strip, intent_name , language)
        arc = {variable_name: condition[0], option: {response: get_response(condition[1].strip, language) }, parameter: {value: intent_name}}
      end
    else
      arc = {variable_name: condition[0]}
    end
    return arc
  end

  def import_context_dialogues_data (file , context_id , language)
    self.user_projects.each{|up| up.user_chatbot_session&.destroy!}
    if context_id && Context.find_by(id: context_id)
      raise "Invalid Context" if Context.find_by(id: context_id).project_id != self.id
      Context.find_by(id: context_id).dialogues.destroy_all
    else
      self.dialogues.where(tag: nil).destroy_all
      if self.dialogues.where(tag: nil).empty?
        newcontext = Context.find_or_create_by(project_id: self.id, name: "first_context")
        new_dilog = Dialogue.create!(project_id: self.id , name: "first dialogue", context_id: newcontext.id, action: nil)
        response=Response.create!(response_owner: new_dilog, order: 1)
        ResponseContent.create!(response_id: response.id, content: {"en" => "Hi , how can I help you ? "}, content_type:0)
        context_id = newcontext.id
      end
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
    start_index = 0
    start_index = 1 if arr[0].empty?
    (start_index...arr.length).step(2).each do |i|
      if arr[i][1].upcase == 'N'
        # dialogue node
        responses_arr, _, _ = get_all_responses(arr[i+1], i, language)
        tmp = arr[i].strip.slice(3..-2).gsub(/\s+/,'_')
        dialogue_name, intent_value = tmp.gsub(/\s+/,'_').split(':')
        dialogues[dialogue_name] = {
          context_id: context_id,
          Intent_value: intent_value,
          options: [],
          variables: {},
          responses: responses_arr
        }
        prev_dialogue = dialogue_name
        prev_variable = nil
        arcs[prev_dialogue] = {}

      elsif arr[i][1].upcase == 'O'
        responses_arr, _, _ = get_all_responses(arr[i+1], i, language)
        raise "Option can't have more than one response in DSL file line #{(i+1)/2}. Option defined as #{arr[i+1]}" if responses_arr.length > 1
        if prev_variable and prev_dialogue
          dialogues[prev_dialogue][:variables][prev_variable][:options].push({response: responses_arr.first})
        elsif prev_dialogue
          dialogues[prev_dialogue][:options].push({response: responses_arr.first })
        else
          raise "Option must come after a dialogue [N:..] or variable [V:..] in DSL file line #{(i+1)/2}"
        end

      elsif arr[i][1].upcase == 'V'
        responses_arr, min, max = get_all_responses(arr[i+1], i, language, true)
        tmp = arr[i].strip.slice(3..-2)
        variable_name, entity_type, storage_type, expire_after, save_text = get_variable_information(tmp)
        
        dialogues[prev_dialogue][:variables][variable_name] = {
          entity: entity_type,
          options: [],
          storage_type: storage_type,
          expire_after: expire_after,
          source: "collected",
          responses: responses_arr,
          allowed_range: { :min => min, :max => max },
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
        p "child_name", child_name
        conditions = []
        arr[i+1].split('&').each {|x| conditions.push x.split('=')}
        arcs[prev_dialogue][child_name] = {}
        arcs[prev_dialogue][child_name][:conditions] = []
        
        conditions.each do |condition|
          found =false
          p "condition[0] -> variable name"
          p "condition[1] -> variable option"
          condition[0].strip!
          next if condition[0].downcase == 'true'
          condition[1].strip!  if condition[1].present?
          dialogues.each do |d_name , d_body|
            if !found && d_body[:variables] && d_body[:variables][condition[0]]
              arc = get_arc_information(d_body[:variables][condition[0]][:options], condition, language)
              arcs[prev_dialogue][child_name][:conditions].push(arc)
              found =true
            end
          end
          
          if !found # search in other project variables (created before import)
            self.variables.each do |v|
              if v.name == condition[0] and !found
                arc = get_arc_information(v.options, condition, language)
                arcs[prev_dialogue][child_name][:conditions].push(arc)
                found =true
              end
            end
          end
        end
      else
        render "Format error in line #{(i+1)/2}", status: :bad_request and return
      end
    end
      
    ActiveRecord::Base.transaction do
      self.import_dialogues_dsl(dialogues, arcs)
      Variable.where(name: nil).destroy_all
    end
    
    dialogues
  end
  
end
