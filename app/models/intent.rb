class Intent < ApplicationRecord
  belongs_to :dialogue, optional: false

  def export
    self.attributes.except("id", "created_at", "updated_at", "dialogue_id")
  end
end
