class Variable < ApplicationRecord
  enum source: [:collected, :fetched, :provided]
  enum storage_type: [:normal, :timeseries, :in_session, :in_cache , :timeseries_in_cache]
  belongs_to :dialogue
  belongs_to :project
  has_many :responses, as: :response_owner, dependent: :destroy
  has_many :response_contents, through: :responses
  has_many :options, dependent: :destroy
  has_many :user_data, dependent: :destroy

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
    tmp_options = {}
    self.responses.each do |response|
      tmp_responses.push response.export
    end
    self.options.each do |option|
      tmp_options[option.id] = option.export
    end
    self.attributes.except!("id", "created_at", "updated_at", "dialogue_id", "project_id").merge({
      responses: tmp_responses,
      options: tmp_options,
    })
  end

	def import(associations_data)
		p " in var import with  associations_data === " , associations_data
		associations_data[:options].each do |old_id, option|
			tmp = {
				response: option[:response]
			}
			new_option = self.options.create!(option.except(:response))
			associations_data[:options][old_id][:new_id] = new_option.id
			new_option.import(tmp)
		end
		associations_data[:responses].each do |response|
			tmp = {response_contents: response[:response_contents]}
			self.responses.create!(response.except(:response_contents)).import(tmp)
		end
	end

	def import_dsl(associations_data)
		p " in var import_dsl with  associations_data === " , associations_data
		options_ids = {}
		p "pass"
		associations_data[:options].each do |option|
			tmp = {
				response: option[:response]
			}
			op = self.options.create!(option.except(:response))
			options_ids.merge!({op.id => option})
			op.import(tmp)
		end
		associations_data[:responses].each do |response|
			tmp = {response_contents: response[:response_contents], response_type: response[:response_type]}
			self.responses.create!(response.except(:response_contents)).import(tmp)
		end
		return options_ids
	end

end
