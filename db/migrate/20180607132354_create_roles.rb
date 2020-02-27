class CreateRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :user_projects do |t|
      t.integer :role, :null => false
      t.references :account, null:false
      t.references :user, null:false
      t.references :user_chatbot_session

      t.timestamps
    end
    add_index :user_projects, [:account_id, :user_id], unique: true
  end
end
