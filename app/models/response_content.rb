class ResponseContent < ApplicationRecord
  enum content_type: [:text, :image, :video, :interactive_image, :title, :button, :icon, :payload, :list_url, :list_template, :list_headers]
  belongs_to :response
  
  def export
    self.attributes.except("id", "created_at", "updated_at", "response_id")
  end
end
