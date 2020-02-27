class UserChatbotSession < ApplicationRecord
  has_one :user_project
	belongs_to :context, optional: true
  belongs_to :dialogue, optional: true
  belongs_to :variable, optional: true
  belongs_to :quick_response, class_name: "Dialogue", foreign_key: "quick_response_id", optional: true

	def self.get_or_create(user_id)
		res = self.where(user_id: user_id).first
		return res.nil? ? {result: self.new(user_id: user_id), status: "new"} : {result: res, status: "exist"}
  end

end
