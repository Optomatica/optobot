class RenameTableUeserSessionAndColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :user_sessions, :wit_entities, :cached_entities
    rename_table :user_sessions, :user_chatbot_sessions
  end
end
