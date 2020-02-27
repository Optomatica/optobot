class ModifyUserChatbotSession < ActiveRecord::Migration[5.1]
  def change
    remove_column :user_chatbot_sessions, :user_id
    remove_column :user_chatbot_sessions, :user_data
    remove_column :user_chatbot_sessions, :cached_entities
    remove_column :user_chatbot_sessions, :requirements_ids
    add_reference :user_chatbot_sessions, :user_project
    add_reference :user_chatbot_sessions, :requirement
    add_column :user_chatbot_sessions, :quick_response_id, :integer
    add_column :user_chatbot_sessions, :fallback_counter, :integer
    add_column :user_chatbot_sessions, :prev_session_id, :integer
    add_column :user_chatbot_sessions, :next_session_id, :integer
  end
end
