class CreateChatbotMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :chatbot_messages do |t|
      t.integer :user_id, null: false
      t.string :message, null: false
      t.boolean :is_user_message ,null: false

      t.timestamps
    end
  end
end
