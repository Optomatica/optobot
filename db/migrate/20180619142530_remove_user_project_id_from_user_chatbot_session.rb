class RemoveUserProjectIdFromUserChatbotSession < ActiveRecord::Migration[5.1]
  def change
    remove_column :user_chatbot_sessions, :user_project_id
  end
end
