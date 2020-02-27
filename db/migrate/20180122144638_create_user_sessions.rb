class CreateUserSessions < ActiveRecord::Migration[5.0]
  def change
    create_table :user_sessions do |t|
      t.integer :user_id, null: false
      t.integer :context_id
      t.integer :dialogue_id
      t.json :user_data

      t.timestamps null: false
    end
  end
end
