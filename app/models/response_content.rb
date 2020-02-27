class ResponseContent < ApplicationRecord
  belongs_to :response

  enum content_type: [:text, :image, :video, :interactive_image, :title, :button, :icon]

  def export
		self.attributes.except!("id", "created_at", "updated_at", "response_id")
	end
end
