include APICalls

module ChatbotHelper
  def analyzeText(text, wit_api)
    url = ENV['WIT_AI_URL']
    headers = {Authorization: "Bearer " + wit_api}
    params = {q: text}

    resp = APICalls.getRequest(url,params,headers)
    puts "first put:", resp.to_json
    myResponse = JSON.parse(resp.body)
    puts myResponse

    entities = myResponse["entities"] ? myResponse["entities"] : myResponse["data"][0]["__wit__legacy_response"]["entities"] # chechk if has muti entity
    return entities
  end
  
  def get_intent(entities)
    return entities["intent"][0] if !entities["intent"].nil?
  end

  def handle_form_response(params)
    @to_render = {}
    p "params[:formResponse] == " ,params[:formResponse]
    params[:formResponse].each{ |variable_name, response|
      if response.class == Array
        response.each {|res|
          create_or_update_user_data(@project.variables.find_by_name(variable_name), res)
        }
      else
        create_or_update_user_data(@project.variables.find_by_name(variable_name), response)
      end
    }
    p "data saved. "
    go_to_next_dialogue(@user_chatbot_session.dialogue)
    @next_context = @user_chatbot_session.context
    save_session
    set_session_response if params[:debug_mode]
    return @to_render
  end

  def chat_process(current_user, project, user_project, params)
    #initialize
    @project = project
    @user_project = user_project
    @current_user = current_user if current_user
    @to_render = {}
    p @user_project, @user_project.user_chatbot_session
    @user_chatbot_session = @user_project.user_chatbot_session

    if @user_chatbot_session.present? && params[:debug_mode]
      # For Debugging: to test a specific session with given context_id / dialogue_id /variable_id
      @user_chatbot_session.variable_id = params[:variable_id] if params[:variable_id].present?

      if params[:dialogue_id].present?
        @user_chatbot_session.dialogue_id = params[:dialogue_id]
      elsif params[:variable_id]
        @user_chatbot_session.dialogue_id = UserChatbotSession.where(variable_id: params[:variable_id] ).pluck(:dialogue_id)
      end

      if params[:context_id].present?
        @user_chatbot_session.context_id = params[:context_id]
      elsif  params[:dialogue_id]
        @user_chatbot_session.context_id = UserChatbotSession.where(dialogue_id: params[:dialogue_id] ).pluck(:context_id).first
      end

      @user_chatbot_session.save!
      @user_chatbot_session = UserChatbotSession.find(@user_chatbot_session.id)
      p "@user_chatbot_session updated ============ " , @user_chatbot_session , @user_chatbot_session.dialogue_id
    end
    @next_context = nil
    @next_dialogue = nil
    @next_variable = nil
    @next_quick_response = nil
    @missing_variables_table = {} # source(collected/fetched) => Hash {variable(object) => count times it is required}
    @is_fallback = false
    @problem = nil

    user_message = ChatbotMessage.create!(user_project_id: @user_project.id, message: params[:text], is_user_message: true) if !params[:debug_mode]

    if @user_chatbot_session.nil? # first time
      p "it’s the first time for the user to chat with the bot. "
      call_wit_and_set_entities_and_intent
      go_to_onboarding
    elsif @user_chatbot_session.variable # context and dialogue and variable
      p " session with variable"
      @next_context = @user_chatbot_session.context
      @next_dialogue = @user_chatbot_session.dialogue
      p "@next_context == " , @next_context
      p "@next_dialogue == " , @next_dialogue
      getting_variable_or_next_dialogue_process
    else
      p "this shouldn't happen but just in case it happent we don't want to lose what the user said"
      call_wit_and_set_entities_and_intent
      handle_intent
    end

    if @problem
      p "@problem ============= " , @problem
      if !params[:debug_mode]
        @problem.chatbot_message_id = user_message.id
        @problem.save!
        users = @project.user_projects.where(role: [:admin,  :author, :moderator, :editor])
        UserMailer.problem_in_chatbot(users, @problem.problem_type)
      end
      new_intent_process_d
      increase_quick_response
    end
    puts "saving user session"

    p @next_variable
    save_session
    puts "user session saved"
    if params[:debug_mode]
      set_session_response
    else
      # save each responses in chatbot_messages history
      @to_render.slice(:dialogue, :variable).each do |_, tmp_to_render|
        tmp_to_render[:responses].each do |response|
          response.each do |_, value|
            ChatbotMessage.create(user_project_id: @user_project.id, message: value, is_user_message: false) unless value.nil?
          end
        end
      end
    end
    return @to_render
  end

  def set_session_response
    if @user_chatbot_session.dialogue_id.nil?
      @user_chatbot_session.dialogue_id = @to_render[:dialogue] && @to_render[:dialogue][:id]
    end
    @to_render[:user_chatbot_session] = @user_chatbot_session
  end

  def go_to_onboarding
    p "in go_to_onboarding"
    p "params[:text] ======== " , params[:text]
    p "@intent ======== " , @intent
    intent_arr = [params[:text]]
    intent_arr << @intent["value"].downcase if @intent

    dialogues = @project.dialogues.joins(:intent).select("dialogues.*").where("intents.value in (?)", intent_arr)
    user_intent = dialogues.first.intent unless dialogues.empty?
    if user_intent
      p "user_intent =========== ", user_intent
      @next_dialogue = user_intent.dialogue
      p "@next_dialogue =========== ", @next_dialogue
      @next_context = @next_dialogue.context
      p "@next_context =========== " , @next_context
    else
      @next_context = @project.contexts.where(name: "first_context").first
      @next_dialogue = @project.dialogues.where(name: "greeting").first
    end

    unless @next_dialogue
      @problem = @project.problems.new(problem_type: :do_not_understand)
      @user_chatbot_session = UserChatbotSession.create!(context_id: nil, dialogue_id: nil)
      @user_project.user_chatbot_session = @user_chatbot_session
      @user_project.save!
      return
    end
    @user_chatbot_session = UserChatbotSession.create!(context_id: @next_context.id, dialogue_id: @next_dialogue.id)
    @user_project.user_chatbot_session = @user_chatbot_session
    @user_project.save!

    set_to_render_response(@next_dialogue)
    go_to_next_dialogue @next_dialogue
  end

  def call_wit_and_set_entities_and_intent (value = params[:text])
    return unless @entities.nil?
    p " in call_wit_and_set_entities_and_intent  with value === #{value}"
    @entities = analyzeText(value, @project.nlp_engine[@lang])
    @intent = get_intent(@entities)
    p 'entities = ' , @entities , " intent = " , @intent
    @entities
  end

  def handle_intent
    if @intent
      @user_chatbot_session.context.nil? ? new_intent_process_no_context : new_intent_process
    else
      @problem = @project.problems.new(problem_type: :do_not_understand)
      @is_fallback = true
    end
  end

=begin
##################################################### Handling user intent #####################################################
  New intent process: If user give a new intent:

  A - search in dialogues in current context with current user intent (intent collected from last user statement).
    If more than one dialogue match the current intent, return first one and report problem to author

  B - search in other contexts dialogues intents
      - if number of dialogues matched > 1 and in same context return first one and report problem to author
      - if number of dialogues matched > 1 and in different contexts, say fallback ( Do you mean .. or .. )

  C - search in knowledge base for quick replies (dialogues with context_id = null and has intent)

  D - fallback (I don’t understand) This intent is not handled in this project
=end

  def new_intent_process
    if dialogue = new_intent_process_a
      p "new_intent_process_a true"
      @next_dialogue = dialogue
      @user_project.delete_cached_user_data
      set_to_render_response(@next_dialogue)
      @next_context = @next_dialogue.context
      @user_project.delete_session_user_data
      go_to_next_dialogue(@next_dialogue)
    else
      new_intent_process_no_context
    end
  end

  def new_intent_process_a
    p " in new_intent_process_a ............."
    if @intent
      dialogues = @project.dialogues.get_dialogues_by(@intent, @user_chatbot_session.context_id)
      p "get_dialogues_by intent = #{@intent}  === ",dialogues
      @problem = @project.problems.new(problem_type: :multiple_intent_in_same_context) if dialogues.length > 1
      return dialogues.first
    else
      # no intent
      @next_context = @user_chatbot_session.context
      @next_dialogue = @user_chatbot_session.dialogue
      @next_variable = @user_chatbot_session.variable
      @is_fallback = true
      @problem = @project.problems.new(problem_type: :do_not_understand)
      return false
    end
  end

  def new_intent_process_no_context
    if dialogue = new_intent_process_b
      p "new_intent_process_b true"
      return if dialogue == :conflict
      @next_dialogue = dialogue
      @user_project.delete_cached_user_data
      set_to_render_response(@next_dialogue)
      @next_context = @next_dialogue.context
      @user_project.delete_session_user_data
      go_to_next_dialogue(@next_dialogue)
    elsif @next_quick_response = new_intent_process_c
      p "new_intent_process_c true"
      @next_context = @user_chatbot_session.context
      @next_dialogue = @user_chatbot_session.dialogue
      @next_variable = @user_chatbot_session.variable
      increase_quick_response
    else
      p "not A or B or C"
      @next_context = @user_chatbot_session.context
      @next_dialogue = @user_chatbot_session.dialogue
      @next_variable = @user_chatbot_session.variable
      @is_fallback = true
      @problem = @project.problems.new(problem_type: :do_not_understand)
    end
  end

  def new_intent_process_b
    return nil unless @intent
    p " in new_intent_process_b ............."
    # search in other contexts dialogues intents, return dialogue if found
    dialogues = @project.dialogues.get_dialogues_by(@intent)
    p "dialogues got by get_dialogues_by: #{dialogues.to_json}"
    return dialogues.first if dialogues.length == 1
    if !dialogues.blank? and Dialogue.in_same_context?(dialogues, dialogues.first.context_id)
      @problem = @project.problems.new(problem_type: :multiple_intent_in_same_context)
      return dialogues.first
    elsif !dialogues.blank?
      # if number of roots matched > 1 and in different contexts, say fallback 
      # do you mean...
      @to_render[:variable] = {}
      response = {en:"Sorry, but do you mean by that for:"}
      @to_render[:variable][:responses] = [{text: response[@lang.to_sym], image: nil, video: nil}]
      @to_render[:variable][:options] = dialogues.pluck(:name).map{|d| {text: d}}
      p "to render", @to_render.to_json
      @next_context = nil
      @next_dialogue = nil
      @next_variable = nil
      @next_quick_response = nil
      return :conflict
    end
  end

  def new_intent_process_c
    p " in new_intent_process_C ............."
    see_in_knowledge_base
  end

  def new_intent_process_d
    p " in new_intent_process_d ............."
    d = (@problem ? Dialogue.get_fallback(@project.id ,@problem.problem_type) : Dialogue.get_fallback(@project.id))
    return unless d
    @problem = @project.problems.new(problem_type: :do_not_understand) if @problem.nil?
    @next_quick_response = d
    set_to_render_response(d, false)
    return d
  end

  def save_session
    unless @is_fallback
      @user_chatbot_session.fallback_counter = 0
    end
    unless @next_context.nil?
      @user_chatbot_session.context = @next_context
      @user_chatbot_session.dialogue = @next_dialogue
    end
    @user_chatbot_session.variable = (@next_variable.class != Array and @next_variable.present?) ? @next_variable : nil
    @user_chatbot_session.dialogue = @next_dialogue || (@next_dialogue && @next_variable.dialogue)
    @user_chatbot_session.save!
  end

  def increase_quick_response
    return unless @next_quick_response
    p "in increase_quick_response "
    p "@next_quick_response === " , @next_quick_response
    p "@user_chatbot_session ====" , @user_chatbot_session
    # @is_fallback = true
    if @user_chatbot_session.quick_response_id == @next_quick_response.id
      @user_chatbot_session.fallback_counter += 1
    else
      @user_chatbot_session.fallback_counter = 1
    end
    if @user_chatbot_session.fallback_counter > @project.fallback_setting["fallback_counter_limit"]
      d = Dialogue.get_fallback(@project.id, :fallback_limit_exeeded)
      @problem = @project.problems.new(problem_type: :fallback_limit_exeeded)
      set_to_render_response(d)
    end
  end

  # TODO 1: if more than one variable hava same entity type
  def match_variable_and_save_values_in_user_data(variables)
    return if @entities.nil?
    variables.each do |variable|
      variables_accurate_filling_and_save_values_in_user_data(variable, true)
    end
  end

  def go_to_next_dialogue(dialogue)
    p "in go_to_next_dialogue given dialogue = " , dialogue
    if @next_variable.nil? and dialogue.children.count != 0
      set_missing_variables_table(dialogue)
      if is_missing_variable_needed_in_all_arcs?(dialogue, "provided")
        p "technical problem"
        @is_fallback = true
        @problem = @project.problems.new(problem_type: :provided_data_missing)
        return
      end

      tmp_dialogue = get_the_dialogue_with_max_number_of_conditions(dialogue.children_arcs)
      if tmp_dialogue
        @next_dialogue = tmp_dialogue
        @user_project.delete_cached_user_data
        set_to_render_response(@next_dialogue)
        go_to_next_dialogue(@next_dialogue)
      else 
        set_next_variable(dialogue)
        if @next_variable
          set_to_render_response(@next_variable)
        else
          p "can't set next variable and can't find dialogue with matching conditions"
          @is_fallback = true
          @problem = @project.problems.new(problem_type: :technical_problem)
        end
      end
    elsif dialogue.children.count == 0
      @next_dialogue = @next_variable = nil
      @user_project.delete_cached_user_data
      p " it's a dialogue without children "
    end
  end

  def getting_variable_or_next_dialogue_process
    p " in getting_variable_or_next_dialogue_process "
    tmp = check_is_variable_satisfied
    if tmp == :ok
      p "check_is_variable_satisfied returns true "
      go_to_next_dialogue(@user_chatbot_session.dialogue)
    elsif tmp == :extra_entities # set_to_render is set to ask the user the about them already
      return
    else
      call_wit_and_set_entities_and_intent
      p "@entities ============== " , @entities
      if @entities.empty?
        @problem = @project.problems.new(problem_type: :do_not_understand)
        @next_variable = @user_chatbot_session.variable
      elsif @entities and new_intent_process != false
        return
      else
        @to_render[:dialogue] = nil
        @next_variable = @user_chatbot_session.variable
        if @user_chatbot_session.variable_id
          if tmp == :not_allowed_value
            @is_fallback = true
            @problem = @project.problems.new(problem_type: :not_allowed_value)
          end
          set_to_render_response(@user_chatbot_session.variable)
        end
      end
    end
  end

  def check_is_variable_satisfied
    p "in check_is_variable_satisfied with var === " , @user_chatbot_session.variable
    if @user_chatbot_session.variable.options.length > 0 and o = bypass_nlp?(@user_chatbot_session.variable)
      return :ok
    else
      if @user_chatbot_session.variable.save_text
        @user_project.user_data.create!(variable_id: @user_chatbot_session.variable.id, value: params[:text])
        return :ok
      elsif @user_chatbot_session.variable.options.length == 0
        status = variables_accurate_filling_and_save_values_in_user_data(@user_chatbot_session.variable)
        if status == :ok
          return :ok
        else
          call_wit_and_set_entities_and_intent
          variables_accurate_filling_and_save_values_in_user_data(@user_chatbot_session.variable)
        end
      end
    end
  end

  def variables_accurate_filling_and_save_values_in_user_data(variable, take_first_entity = false)
    puts "in variables accurate filling given variable == " , variable.name
    if variable.entity.nil? or variable.entity.blank?
      p "this variable should have entity"
      return :no_entity
    elsif @entities.present? and @entities[variable.entity].present? and 
        ((variable.unit.nil? and @entities[variable.entity][0]["unit"].nil?) or 
         (variable.unit and @entities[variable.entity][0]["unit"] and 
          @entities[variable.entity][0]["unit"].to_unit =~ variable.unit.to_unit))

      if @entities[variable.entity].length > 1 and take_first_entity == false
        p "in extra entities"
        options = generate_all_possible_options(@entities[variable.entity])

        @to_render[:variable] = {}
        response = {en:"Sorry, but do you mean for #{variable.name}:"}
        @to_render[:variable][:responses] = [{text: response[@lang.to_sym], image: nil, video: nil}]
        @to_render[:variable][:options] = options
        @next_context = @user_chatbot_session.context
        @next_dialogue = @user_chatbot_session.dialogue
        @next_variable = @user_chatbot_session.variable
        p "to render", @to_render.to_json
        return :extra_entities
      else
        tmp = get_value_satisfy_variable(variable)
        if tmp[:status] == :not_allowed_value or tmp[:status] == :out_of_range
          return :not_allowed_value
        elsif tmp[:status] == :ok
          puts "variable:", variable.to_json, " satisfied!"
          create_or_update_user_data(variable, tmp[:value])
          p " data saved  "
          @user_chatbot_session.variable_id = nil
          return :ok
        end
      end
    else
      return :no_match
    end
  end

  def create_or_update_user_data(variable, value, option_id = nil)
    p " in create_or_update_user_data given variable and value ===  " ,variable, value
    if variable.entity == "number" and !is_number?(value)  # check if text has digits only
      p " invalid entity type _______ variable.entity = #{variable.entity}  & value == #{value}"
      return
    end
    tmp = @user_project.user_data.where(variable_id: variable.id).last
    if tmp and (tmp.variable.expire_after and tmp.variable.storage_type != "timeseries" and 
      (Time.now - tmp.updated_at) >= tmp.variable.expire_after*60)
        # value exists but expired and not of type timeseries
        tmp.update_attributes(value: value, option_id: option_id)
    else
      p "creating new user data "
      @user_project.user_data.create!(variable_id: variable.id, value: value, option_id: option_id)
    end
  end

  def set_next_variable(dialogue)
    p " in set next variable  given dialogue = " , dialogue
    if dialogue.form_node
      @next_variable = dialogue.variables.to_a
    else
      @next_variable = get_variable_with_highest_periority
    end
    p "@next_variable === " , @next_variable
  end

  def get_variable_with_highest_periority(source = "collected")
    p " in get_variable_with_highest_periority "
    @missing_variables_table[source].key(@missing_variables_table[source].values.max) if @missing_variables_table[source].present?
  end

  def is_missing_variable_needed_in_all_arcs?(dialogue, source = "collected")
    p " in is_variable_needed_in_all_arcs given source = #{source} and dialogue == " , dialogue
    @missing_variables_table[source].values.max <= dialogue.children_arcs.length if @missing_variables_table[source].present?
  end

  def set_missing_variables_table(dialogue)
    p " in set_missing_variables_table given dialogue =  ", dialogue
    if (@entities)
      match_variable_and_save_values_in_user_data(dialogue.variables.where(source: :collected))
    end
    @user_project.delete_expired_data

    satisfied_variables_ids = @user_project.user_data.where.not(expired: true).pluck(:variable_id).uniq
    satisfied_conditions = Condition.where(variable_id: satisfied_variables_ids)
    p "satisfied_conditions", satisfied_conditions
    all_conditions = Condition.get_conditions_by(dialogue.id, dialogue.children.ids)
    p "all conditions", all_conditions
    unsatisfied_conditions = all_conditions - satisfied_conditions
    p "unsatisfied_conditions", unsatisfied_conditions
    @missing_variables_table = {}
    unsatisfied_conditions.map do |c| 
      if @missing_variables_table[c.variable.source] 
        @missing_variables_table[c.variable.source][c.variable] = 0 
      else
        @missing_variables_table[c.variable.source] = {c.variable => 0 }
      end
    end

    unsatisfied_conditions.each do |condition|
      if @missing_variables_table[condition.variable.source] 
        @missing_variables_table[condition.variable.source][condition.variable] = 0
      else 
        @missing_variables_table[condition.variable.source] = {condition.variable => 0 }
      end
      @missing_variables_table[condition.variable.source][condition.variable] += 1
    end
    p "@missing_variables_table", @missing_variables_table
  end

  def is_number? string
    true if Float(string) rescue false
  end

  def get_variable_data(var_name)
    if is_number?(var_name)
      return var_name
    else
      is_all = var_name.ends_with?(".all")
      var_name = var_name[0...-4] if is_all
      var = @project.variables.find_by_name(var_name)
      user_data = @user_project.user_data.where(variable_id: var.id) unless var.nil?
      return nil if user_data.empty?
      if is_all
        return user_data.pluck(:value).map{|value| is_number?(value) ? value.to_f : value}
      else
        user_datum = user_data.last
        data_or_option = (user_datum.option_id && user_datum.option.value) ? user_datum.option : user_datum
        return (data_or_option and data_or_option.variable.unit) ? Unit.new("#{data_or_option.value} #{data_or_option.variable.unit}") : data_or_option.value
      end
    end
  end

  def get_arguments(variable)
    num_arr = []
    variable.fetch_info['arguments'].each do |item|
      ud = get_variable_data(item)
      return nil if ud.nil?
      if ud.is_a? Array
        num_arr += ud
      else
        num_arr.push(ud)
      end
    end
    return num_arr
  end

  def get_fetched_data(variable)
    p "in get_fetched_data given variable = " , variable
    value = nil
    if variable.fetch_info['url']
      "variable.fetch_info ================= URL "
      uri = URI.parse(URI.encode(fix_response_text(variable.fetch_info['url'])))
      headers = variable.fetch_info['headers']
      body = variable.fetch_info['body']
      method_type = variable.fetch_info['method_type']
      key = variable.fetch_info['key']
      p "uri === " , uri
      body = fix_response_text(body) if body
      p "uri_Mustache === " , uri
      request = method_type == 'post' ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      headers.keys.each{|k|
        request[k] = fix_response_text(headers[k])
      }
      request.content_type = "application/json"
      request["Cache-Control"] = "no-cache"
      request.body = body if method_type == 'post'
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      response = JSON.parse(response.body) rescue response.body
      value = nil
      if response.class == Hash
        p "response.class = Hash "
        req_response_arr = key.split('.')

        req_response_arr.each { |item|
          if response[item]
            response = response[item]
          else
            response = nil
            break
          end
        }

        value = response
        p "value =" , value
      elsif response.class == String
        p "response.class = string "
        value = response
        p "value = #{value} "
      else
        p "not hash or string!!"
      end
    else
      arr = get_arguments(variable)
      return unless arr
      value = send(variable.fetch_info['function'], arr) rescue nil
    end
    unless value.nil?
      create_or_update_user_data(variable, value)
      return true
    end
  end

  def bypass_nlp?(variable)
    # if we will bypass nlp, we will save value in user data here as well
    p "in bypass_nlp? given variable = " , variable
    options = Option.where(variable_id: variable.id)
    option = nil
    options.find do |x|
      p "option", x.response.response_contents
      option = x if x.response.response_contents.index{|z| z.content[@lang].downcase == params[:text].downcase}
    end
    if option
      create_or_update_user_data(variable, option.response.response_contents.last.content[@lang], option.id)
      @entities = {}
    end
    return option
  end

  def see_in_knowledge_base
    dialogues = @project.dialogues.get_knowledge_base_dialogues(@intent)
    @problem = @project.problems.new(problem_type: :multiple_intent_in_same_context) if dialogues.length > 1
    return dialogues.first
  end

  def fix_response_text(responses, replacements={})
    p 'in fix_response_text with  responses ==', responses, responses.class
    if [URI::HTTPS, URI::HTTP, String].include?(responses.class)
      get_mustache_value responses.to_s, replacements
    elsif responses.is_a?(Array)
      responses.each do |response|
        response.keys.each { |key| 
          response[key] = get_mustache_value response[key], replacements 
        }
        p 'response after replacment ======', response
      end
    else
      get_mustache_value responses
    end
  end

  def get_mustache_value(response, replacements)
    spaces_replaced = response.nil? ? "" : response.gsub(/\{\{(.*?)\}\}/) {|x| "{{#{x[2...-2].strip.gsub(/\s+/,'_')}}}"}
    matches = spaces_replaced.scan(/\{\{(.*?)\}\}/)
    if matches.present?
      p " your text contain curly brackets ............."
      puts "matches", matches.to_json ,".........."
      matches.each do |matched|
        matched = matched[0]
        if matched == "user_name" and @current_user and @current_user.name
          replacements[matched] = @current_user.name
        else
          user_datum = get_variable_data(matched)
          next if user_datum.nil?
          new_matched = matched.gsub(".", "")
          response.gsub!(matched, new_matched)
          replacements[new_matched] = user_datum
        end
      end

      response = Mustache.render(response, replacements)
    end
    return response
  end

  def set_to_render_response(reply_owner, overwrite = true)
    p " in set_to_render_response...... given reply_owner == " , reply_owner
    p "reply_owner.class == " , reply_owner.class
    kind = reply_owner.class == Array ? :form : ((reply_owner.class == Dialogue) ? :dialogue : :variable)
    p "kind == " , kind
    if !overwrite and @to_render[kind]
      return
    end

    if reply_owner.class == Array
      p "reply_owner.class = Array (for variables)"
      @to_render[kind]= reply_owner.map{|variable|
        v = {name: variable.name, type: variable.entity}
        all_responses = variable.get_responses(@lang)
        all_responses.each do |response_type, response_content|
          fix_response_text response_content unless response_content == []
        end
        v.merge(all_responses)
        v[:options] = variable.get_options(@lang)
        v[:dialogue_name] = variable.dialogue.name
        v
      }
    else
      all_responses = reply_owner.get_responses(@lang)
      all_responses.each do |response_type, response_content|
        fix_response_text response_content unless response_content == []
      end
      if @to_render[kind]
        all_responses.each {|key, value| 
          @to_render[kind][key] = (@to_render[kind][key] || []) + value
        }
      else
        @to_render[kind] = all_responses
      end
      @to_render[kind][:options] = reply_owner.get_options(@lang) if reply_owner.class == Variable
      @to_render[kind][:dialogue_name] = reply_owner.dialogue.name if kind == :variable
      @to_render[kind][:dialogue_name] = reply_owner.name if kind == :dialogue
      @to_render[kind][:id] = reply_owner.id if kind == :dialogue
      @to_render[kind][:variable_name] = reply_owner.name if kind == :variable
      @to_render[kind][:storage_type] = reply_owner.storage_type if kind == :variable
    end
    p " set_to_render_response will render @to_render ============= " , @to_render
  end

  def check_for_conditions(arc)
    p "in check_for_conditions given arc = ", arc
    return true if arc.conditions.blank?
    return arc.conditions.all?{|c|
      p "condition === " , c
      p "@user_project , c.variable , c.variable_id================ "  , @user_project , c.variable , c.variable_id
      p "@user_project.user_data ==================== " , @user_project.user_data
      p "condition.variable === " , c.variable

      if c.variable.source == "fetched"
        return nil if !get_fetched_data(c.variable)
      end

      data = @user_project.user_data.where(variable_id: c.variable_id).last
      p "data = " , data
      p "data.variable.expire_after == ", data.variable.expire_after if data.present?
      return nil if data.nil? or (data.variable.expire_after and ((Time.now - data.updated_at) >= data.variable.expire_after*60)) or (c.variable.storage_type == "timeseries_in_cache"  and data.expired? )
      p "data.option = " , data.option , data.option_id
      p "data.value = " , data.value
      data_or_option = (data.option_id && data.option.value) ? data.option : data#
      p "data_or_option = " , data_or_option
      begin
        if c.parameter_id.nil? and c.option_id.nil?
          res =true
        else
          p "it's fetched variable" if data.variable.source == "fetched"
          res = (c.option && data.option_id && (data.option_id == c.option_id)) ||
            (c.option && data.value && (data.value == c.option.value)) ||
            (c.parameter.value && data.value && (data.value == c.parameter.value )) ||
            (c.parameter_id && data.variable.entity &&(
              (c.parameter.value && data_or_option.value == c.parameter.value)||
              ((c.parameter.min && data_or_option.value.to_i >= c.parameter.min) &&
              (c.parameter.max && data_or_option.value.to_i <= c.parameter.max)) ||
              ((c.parameter.min && data_or_option.value.to_i >= c.parameter.min) && (c.parameter.max == nil )) ||
              ((c.parameter.max && data_or_option.value.to_i <= c.parameter.max) && (c.parameter.min == nil))
              ))
        end

      rescue => e
        p e.message # this will happen if data.value == nil or if the author by mistake put uncompatibile units in parameter and variable ==> both conditions shouldn't happen
        res = false
      end
      res
    }
  end

  def get_the_dialogue_with_max_number_of_conditions(children_arcs)
    p "in get_the_dialogue_with_max_number_of_conditions given children_arcs === " , children_arcs
    return nil if children_arcs.blank? or @user_project.user_data.blank?
    p "children_arcs.class", children_arcs[0].class
    arcs = children_arcs.sort{|a,b| b.conditions.length <=> a.conditions.length }
    arcs.each do |arc|
			puts "arc", arc.to_json
      p "arc.conditions.count ==== " , arc.conditions.count
			matched = check_for_conditions(arc)
      if matched
        p "matched =====  #{matched} "
        return arc.child
      end
    end
    p "no arc matched"
		return nil
  end

  def generate_all_possible_options(entities)
    options = []
    keys_to_extract = ["value","unit"]
    tmp = entities.map do |w|
      ww = w.select { |k,_| keys_to_extract.include? k }
      if ww.values.length == 2
        "#{ww.values[0]} #{ww.values[1]}(s)"
      else
        "#{ww.values[0]}"
      end
    end
    tmp.each do |op|
      options.push({text: op})
    end
    return options
	end

  def get_value_satisfy_variable(variable)
    p "getting value"
    value = nil
    in_range = in_possible_values = nil
    if variable.possible_values and variable.possible_values.present?
      in_possible_values = variable.possible_values.include?(@entities[variable.entity][0]["value"]) and variable.possible_values.include?(@entities[variable.entity][0]["value"])
      value = @entities[variable.entity][0]["value"]
    elsif variable.allowed_range and is_number?(@entities[variable.entity][0]["value"])
      value = Unit.new("#{@entities[variable.entity][0]["value"]} #{@entities[variable.entity][0]['unit']}").convert_to(variable.unit).to_s.to_i
      in_range = (variable.allowed_range["min"].nil? or variable.allowed_range["min"] <= value) and (variable.allowed_range["max"].nil? or value <= variable.allowed_range["max"])
    else
      if variable.unit and variable.unit.to_unit != @entities[variable.entity][0]['unit'] # but I know its compatible
        value = Unit.new("#{@entities[variable.entity][0]["value"]} #{@entities[variable.entity][0]['unit']}").convert_to(variable.unit).to_s.to_i
      else
        value = @entities[variable.entity][0]['value']
      end
    end
    if (in_range.nil? and in_possible_values.nil?) or in_range or in_possible_values # satisfied
      @entities[variable.entity].shift
      @entities.except!(variable.entity) if @entities[variable.entity].empty?
      return {value: value, status: :ok}
    elsif in_range == false or in_possible_values == false
      return {status: in_range == false ? :out_of_range : :not_allowed_value, value: value}
    end
    p "value returned, #{value}"
		return {value: value}
  end

end
