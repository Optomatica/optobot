class ResponseContent < ApplicationRecord
  enum content_type: [:text, :image, :video, :interactive_image, :title, :sub_title, :button_type,
                      :icon, :list_url, :list_template, :list_headers, :button_title,
                      :button_url, :button_text, :card_image, :button_payload, :receipt, :order_number,
                      :currency, :payment_method, :total_cost, :element, :quantity, :price, :image_url, 
                      :card, :slider_text, :typing, :json, :graph, :data_request, :view, :rating, :command]
  belongs_to :response
  
  def export
    self.attributes.except("id", "created_at", "updated_at", "response_id")
  end
end
