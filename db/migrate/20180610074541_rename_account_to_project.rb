class RenameAccountToProject < ActiveRecord::Migration[5.1]
  def change
    rename_table :accounts, :projects
    remove_column :projects, :admin_user_id
    rename_column :projects, :nlp_api_token, :nlp_engine
    add_column :projects, :name, :string
    add_column :projects, :external_backend, :json
    add_column :projects, :is_private, :boolean, default: false
    add_column :projects, :fallback_setting, :json
  end
end
