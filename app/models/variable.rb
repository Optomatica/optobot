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
    Response.response_types.each { |k, _| my_responses[k.pluralize.to_sym] = [] }

    self.responses.order(:order).each do |response|
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
    tmp_responses = {responses: self.responses.map(&:export) }
    tmp_options = { options: self.options.map { |o| [o.id, o.export] }.to_h }

    exempted_keys = ["id", "created_at", "updated_at", "dialogue_id", "project_id"]
    self.attributes.except(*exempted_keys).merge(tmp_responses, tmp_options)
  end

  def import(associations_data)
    p " in var import with  associations_data === " , associations_data

    associations_data[:options].each do |_, option|
      new_option = self.options.create!(option.except(:response))
      option[:new_id] = new_option.id
      new_option.import(response: option[:response])
    end

    associations_data[:responses].each do |response|
      new_response = self.responses.create!(response.except(:response_contents))
      new_response.import(response_contents: response[:response_contents])
    end
  end

  def import_dsl(associations_data)
    p " in var import_dsl with  associations_data === " , associations_data, "pass"

    options = associations_data[:options].map do |option|
      new_option = self.options.create!(option.except(:response))
      new_option.import(response: option[:response])
      [new_option.id, option]
    end

    associations_data[:responses].each do |response|
      new_response = self.responses.create!(response.except(:response_contents))
      new_response.import(response_contents: response[:response_contents], response_type: response[:response_type])
    end

    return options.to_h
  end
end
