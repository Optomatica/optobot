include DslError

class Dialogue < ApplicationRecord
	belongs_to :context, optional: true
	belongs_to :project

	has_many :user_chatbot_session, dependent: :restrict_with_exception

	has_many :responses, as: :response_owner, dependent: :destroy
	has_many :variables, dependent: :destroy

	has_many :children_arcs, class_name: "Arc",
									foreign_key: "parent_id",
									dependent: :destroy
	has_many :parents_arcs, class_name: "Arc",
									foreign_key: "child_id",
									dependent: :destroy
 	has_many :children, through: :children_arcs, source: :child
	has_many :parents, through: :parents_arcs, source: :parent
	has_one :intent, dependent: :destroy

	def self.get_fallback(project_id , fallback_type = "do_not_understand")
		fallback_type = "do_not_understand" if fallback_type == :provided_data_missing
		return self.where(tag: "fallback/" + fallback_type.to_s, project_id: project_id).first
	end

	def self.get_knowledge_base_dialogues(intent)
		self.get_dialogues_by(intent, nil)
	end

	def self.get_dialogues_by(intent, context_id = -1)
		return [] if intent.nil?
		intent_value = intent["value"]
		p "in get_dialogues_by given intent #{intent} and intent value = #{intent_value} and context_id = #{context_id}"

		if context_id == -1
			allDialogues = self.joins(:intent).select("dialogues.*").where("intents.value =?", intent["value"].downcase)
			return allDialogues
		else
			allDialogues = self.joins(:intent).select("dialogues.*").where("intents.value =?", intent["value"].downcase).where(context_id: context_id)
			allDialogues = self.joins(:intent).select("dialogues.*").where("intents.value =?", intent["value"].downcase) if allDialogues.empty?
			return allDialogues
		end
	end

	def self.in_same_context?(dialogues, context_id)
	  dialogues.all? {|a| a.context_id == context_id}
	end

  def get_responses(lang)
    my_responses = {}
    Response.response_types.each {|k, _| my_responses[k.pluralize.to_sym] = []}
		tmp = self.responses.order(:created_at)
		tmp.each do |response|
			res_hash = response.get_contents(lang)
			res_type = response.response_type.pluralize.to_sym
			my_responses[res_type].push(res_hash)
		end
		return my_responses
	end

	def get_options(lang)
		my_options=[]
    	self.options.each do |option|
      	my_options += option.get_responses(lang)
		end
		return my_options
	end

	def export
		tmp_responses = []
		tmp_variables = {}

		tmp_intent = self.intent.export if self.intent

		self.responses.each do |response|
			tmp_responses.push response.export
		end
		self.variables.each do |variable|
			tmp_variables[variable.id] = variable.export
		end
		self.attributes.except!("id", "created_at", "updated_at", "project_id").merge({
			intent: tmp_intent,
			responses: tmp_responses,
			variables: tmp_variables,
		})
	end

	def import(associations_data)
		p associations_data
		associations_data[:variables].each do |old_id, variable|
			tmp = {
				options: variable[:options],
				responses: variable[:responses]
			}
			variable[:project_id] = self.project_id
			new_variable = self.variables.create!(variable.except(:options, :responses))
			associations_data[:variables][old_id][:new_id] = new_variable.id
			new_variable.import(tmp)
		end
		associations_data[:responses].each do |response|
			tmp = {response_contents: response[:response_contents] ,response_type: response[:response_type]}
			self.responses.create!(response.except(:response_contents)).import(tmp)
		end
	end

	def import_dsl(associations_data, dsl_lines)
		p " in dialogue import_dsl with  associations_data === " , associations_data

		options_ids = {}
		variable = self.variables.create!( project_id: self.project_id )
		associations_data[:options].each do |option|
			tmp = {
				response: option[:response]
			}
			op = variable.options.create!(option.except(:response))
			options_ids.merge!({op.id => option})
			op.import(tmp)
		end
		associations_data[:variables].each do |variable_name, variable|
			tmp = {
				options: variable[:options],
				responses: variable[:responses]
      		}
      		new_variable = self.variables.create!( {name: variable_name, project_id: self.project_id}.merge(variable.except(:options, :responses)) )
			options_ids.merge!(new_variable.import_dsl(tmp))
		end if associations_data[:variables]

		associations_data[:responses].each do |response|
			p response[:response_contents].first[:content][:en]
			if response[:response_contents].first[:content][:en] != ""
			    tmp = {response_contents: response[:response_contents] ,response_type: response[:response_type]}
			    self.responses.create!(response.except(:response_contents)).import(tmp)
			end
		end

		associations_data[:children].each do |child_name, child|
			arc = Arc.create!(parent_id: self.id, child_id: child[:id])
			child[:conditions].each do |condition|
				variable = self.project.variables.where(name: condition[:variable_name]).last
				con = Condition.new(arc_id: arc.id, variable_id: variable.id)
				con.option_id = options_ids.key(condition[:option])
				if con.option_id == nil and condition[:option].present?
					cc = condition[:option][:response][:response_contents].first[:content][:en]
					rr = ResponseContent.joins(:response).joins("join options o on (o.id = responses.response_owner_id and responses.response_owner_type = 'Option')").
						joins("join variables v on (v.id = o.variable_id)").where("v.project_id = #{self.project_id}").where("content->> 'en' = $$#{cc}$$").last
					if rr.nil?
						expected_wrong_line = "[C:#{child_name}]#{variable.name}=#{cc}"
						line_number = get_error_line(dsl_lines, expected_wrong_line)
						raise "undefined option '#{cc}' in DSL file line #{line_number}" 
					end
					con.option_id = rr.response.response_owner_id
				end

				unless condition[:parameter].nil?
					condition[:parameter][:project_id] = self.project_id
					para = Parameter.create!( condition[:parameter])
					con.parameter_id = para.id
				end
				con.save
			end
		end
	end
end
