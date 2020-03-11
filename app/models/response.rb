class Response < ApplicationRecord
  enum response_type: [:response, :hint, :supplementary, :title, :note]

  belongs_to :response_owner, polymorphic: true
  has_many :response_contents, dependent: :destroy

  before_save :only_one_for_option

  def get_contents(lang, count = 1)
    p " in get_contents ====== with lang == #{lang} and count = #{count}"

    responses = {}
    ResponseContent.content_types.each do |content_type, _|
      responses[content_type] = self.response_contents.where(content_type: content_type).where("content ->> '#{lang}' is not NULL")
    end

    self.response_owner_type == "Option" ? format_options(responses, lang, count) : format_response(responses, lang)
  end

  def export
    exempted_keys = ["id", "created_at", "updated_at", "response_owner_id", "response_owner_type"]
    tmp_response_contents = self.response_contents.map(&:export)
    self.attributes.except(*exempted_keys).merge({ response_contents: tmp_response_contents })
  end

  def import(associations_data)
    self.save!
    self.response_contents.create!(associations_data[:response_contents])
  end

  private

  def only_one_for_option
    Response.where(response_owner: self.response_owner).empty?
  end

  def format_response(responses, lang)
    p responses
    formated_responses = responses.map do |key, response|
      next if response.empty?
      rand_index = rand(0...response.length)
      p response[rand_index], lang
      [key.to_sym, response[rand_index].content[lang]]
    end

    return formated_responses.compact.to_h
  end

  def format_options(responses, lang, count)
    # todo get unique counts. There is a chance an option get selected twice
    (0...count).to_a.map { format_response(responses, lang) }
  end
end
