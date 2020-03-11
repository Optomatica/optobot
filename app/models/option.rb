class Option < ApplicationRecord
  belongs_to :variable
  has_one :response, as: :response_owner, dependent: :destroy
  has_many :conditions

  after_destroy :destroy_condition
  after_create :add_response

  def get_responses(lang)
    self.response.get_contents(lang, self.display_count)
  end

  def export
    exempted_keys = ["id", "created_at", "updated_at", "variable_id"]
    self.attributes.except(exempted_keys).merge(response: self.response.export)
  end

  def import(associations_data)
    response = associations_data[:response]
    self.response.import(response_contents: response[:response_contents],
                         response_type: response[:response_type])
  end

  private

  def add_response
    if self.response.nil?
      r = Response.create!({response_owner_id: self.id, response_owner_type: "Option"})
      self.response = r
    end
  end

  def destroy_condition
    self.conditions.each { |condition| condition.destroy if condition.parameter.nil? }
  end
end
