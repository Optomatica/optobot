class Response < ApplicationRecord
	belongs_to :response_owner, polymorphic: true
	has_many :response_contents, dependent: :destroy

	before_save :only_one_for_option

	enum response_type: [:response, :hint, :supplementary, :title, :note]
	
	def get_contents(lang, count = 1)
		" in get_contents ====== with lang == #{lang} and count = #{count}"
		responses = {}
		ResponseContent.content_types.each do |content_type, _|
			responses[content_type] = self.response_contents.where(content_type: content_type).where("content ->> '#{lang}' is not NULL")
		end
		if self.response_owner_type == "Option"
			return format_options(responses, lang, count)
		end
		return format_response(responses, lang)
	end
	
	def export
		tmp_response_contents = []
		self.response_contents.each do |response_content|
			tmp_response_contents.push response_content.export
		end
		self.attributes.except!("id", "created_at", "updated_at", "response_owner_id", "response_owner_type").merge({
			response_contents: tmp_response_contents
		})
	end

	def import(associations_data)
		# self.response_type = associations_data[:response_type]

		self.save!
		associations_data[:response_contents].each do |response_content|
			self.response_contents.create!(response_content)
		end
	end

	private

	def only_one_for_option
		Response.where(response_owner: self.response_owner).length == 0
	end

	def format_response(responses, lang)
		formated_responses = {}
		keys = ["text", "image", "video", "interactive_image", "title", "button", "icon"]

		keys.each do |key|
			index = rand(0...responses[key].length)
			if responses.keys.include?(key) and responses[key].present?
				formated_responses[key.to_sym] = responses[key][index].content[lang]
			end
		end
		
		return formated_responses
	end

	def format_options(responses, lang, count)
		formated_responses = []
		while count > 0 do
			formated_responses << format_response(responses, lang)
			count -= 1
		end
		return formated_responses
	end

end

