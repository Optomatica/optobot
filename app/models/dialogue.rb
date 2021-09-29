include DslError

class Dialogue < ApplicationRecord
  belongs_to :context, optional: true
  belongs_to :project

  has_many :user_chatbot_session, dependent: :restrict_with_exception

  has_many :responses, as: :response_owner, dependent: :destroy
  has_many :variables, dependent: :destroy

  has_many :children_arcs, class_name: "Arc", foreign_key: "parent_id", dependent: :destroy
  has_many :parents_arcs, class_name: "Arc", foreign_key: "child_id", dependent: :destroy

  has_many :children, through: :children_arcs, source: :child
  has_many :parents, through: :parents_arcs, source: :parent
  has_one :intent, dependent: :destroy

	def self.get_fallback(project_id , fallback_type = "do_not_understand")
		fallback_type = "do_not_understand" if fallback_type == :provided_data_missing
		return self.where(tag: "fallback/" + fallback_type.to_s, project_id: project_id).first
	end

  def self.get_knowledge_base_dialogues(intent)
    get_dialogues_by(intent, nil)
  end

  def self.get_dialogues_by(intent, context_id = -1)
    return [] if intent.nil?

    intent_value = intent["name"]
    p "in get_dialogues_by given intent #{intent} and intent value = #{intent_value} and context_id = #{context_id}"

    all_dialogues = self.joins(:intent).select("dialogues.*").where("intents.value =?", intent_value.downcase)
    return all_dialogues.where.not(context_id: nil) if context_id == -1

    context_dialogues = all_dialogues.where(context_id: context_id)
    return context_dialogues
  end

  def self.in_same_context?(dialogues, context_id)
    dialogues.all? { |a| a.context_id == context_id }
  end

  def get_responses(lang)
    my_responses = {}
    Response.response_types.each {|k, _| my_responses[k.pluralize.to_sym] = []}

    self.responses.order(:order).each do |response|
      res_hash = response.get_contents(lang)
      res_type = response.response_type.pluralize.to_sym
      my_responses[res_type].push(res_hash)
    end

    return my_responses
  end

  def get_options(lang)
    self.options.map { |option| option.get_responses(lang) }
  end

  def export
    tmp_intent = self.intent&.export
    tmp_responses = self.responses.map(&:export)
    tmp_variables = self.variables.map { |variable| [variable.id, variable.export] }.to_h
    exempted_keys = ["id", "created_at", "updated_at", "project_id"]

    self.attributes.except(*exempted_keys).merge(intent: tmp_intent, responses: tmp_responses, variables: tmp_variables)
  end

  def import(associations_data)
    p associations_data

    associations_data[:variables].each do |old_id, variable|
      variable[:project_id] = self.project_id
      new_variable = self.variables.create!(variable.except(:options, :responses))
      variable[:new_id] = new_variable.id
      new_variable.import({options: variable[:options], responses: variable[:responses]})
    end

    associations_data[:responses].each do |response|
      new_response = self.responses.create!(response.except(:response_contents))
      new_response.import(response_contents: response[:response_contents], response_type: response[:response_type])
    end
  end

  def import_dsl(associations_data, dsl_lines)
    p " in dialogue import_dsl with  associations_data === " , associations_data

    options_ids = {}
    variable = self.variables.create!(project_id: self.project_id)

    associations_data[:options].each do |option|
      new_option = variable.options.create!(option.except(:response))
      options_ids.merge!(new_option.id => option)
      new_option.import(response: option[:response])
    end

    associations_data[:variables]&.each do |variable_name, variable|
      new_variable_hash = {name: variable_name, project_id: self.project_id }.merge(variable.except(:options, :responses))
      new_variable = self.variables.create!(new_variable_hash)
      options_ids.merge!(new_variable.import_dsl({options: variable[:options], responses: variable[:responses]}))
    end

    associations_data[:responses].each do |response|
      response_content = response[:response_contents].first[:content].values.first
      if response_content != ""
        tmp = {response_contents: response[:response_contents] ,response_type: response[:response_type]}
        self.responses.create!(response.except(:response_contents)).import(tmp)
      end
    end

    associations_data[:children].each do |child_name, child|
      arc = Arc.create!(parent_id: self.id, child_id: child[:id])
      next if arc.update!(go_next: false) if child[:go_next] == false
      child[:conditions].each do |condition|
        variable = self.project.variables.where(name: condition[:variable_name]).last
        new_condition = Condition.new(arc_id: arc.id, variable_id: variable.id)
        option = condition[:option]
        new_condition.option_id = options_ids.key(option)

        if new_condition.option_id == nil && option.present?
          response_content = option[:response][:response_contents].first[:content].values.first
          lang = option[:response][:response_contents].first[:content].keys.first
          new_response_content = ResponseContent.joins(:response).
                joins("join options o on (o.id = responses.response_owner_id and responses.response_owner_type = 'Option')").
                joins("join variables v on (v.id = o.variable_id)").
                where("v.project_id = #{self.project_id}").where("content->> '#{lang}' = $$#{response_content}$$").last

          if new_response_content.nil?
            expected_wrong_line = "[C:#{child_name}]#{variable.name}=#{response_content}"
            line_number = get_error_line(dsl_lines, expected_wrong_line)
            raise "undefined option '#{response_content}' in DSL file line #{line_number}: #{expected_wrong_line}"
          end

          new_condition.option_id = new_response_content.response.response_owner_id
        end

        parameter = condition[:parameter]
        if parameter.present?
          parameter[:project_id] = self.project_id
          new_parameter = Parameter.create!(parameter)
          new_condition.parameter_id = new_parameter.id
        end

        new_condition.save
      end
    end
  end
end
