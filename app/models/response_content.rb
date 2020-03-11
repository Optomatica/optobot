class ResponseContent < ApplicationRecord
  enum content_type: [:text, :image, :video, :interactive_image, :title, :button, :icon]
  belongs_to :response

  def export
    self.attributes.except("id", "created_at", "updated_at", "response_id")
  end
end
