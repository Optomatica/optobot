class AddColumnsToUserSession < ActiveRecord::Migration[5.0]
  def change
    add_column :user_sessions, :wit_entities, :json, default: {}
    add_column :user_sessions, :requirements_ids, :integer, array: true, default: []
  end
end
