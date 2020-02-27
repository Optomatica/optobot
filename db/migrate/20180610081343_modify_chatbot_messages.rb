class ModifyChatbotMessages < ActiveRecord::Migration[5.1]
  def change
    remove_column :chatbot_messages, :user_id
    add_reference :chatbot_messages, :user_project
  end
end
