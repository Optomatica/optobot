class EditSomeColumns < ActiveRecord::Migration[5.0]
  def up
    change_column :user_sessions, :user_data, :json, default: {}
    add_column :dialogues, :kind, :string, default: 'normal',   null: false
  end
  def down
    change_column :user_sessions, :user_data, :json
    remove_column :dialogues, :kind
  end
end
