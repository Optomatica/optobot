class Context < ApplicationRecord
  belongs_to :project
  has_many :user_chatbot_session, dependent: :restrict_with_exception
  has_many :dialogues, dependent: :destroy

  validates :name, presence: true

  def export
    self.attributes.except!("id", "created_at", "updated_at", "project_id")
  end
end
