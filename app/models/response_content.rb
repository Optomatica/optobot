class ResponseContent < ApplicationRecord
  enum content_type: [:text, :image, :video, :interactive_image, :title, :sub_title, :button_type,
                      :icon, :list_url, :list_template, :list_headers, :button_title, :button_payload]
  belongs_to :response
  
  def export
    self.attributes.except("id", "created_at", "updated_at", "response_id")
  end
end
