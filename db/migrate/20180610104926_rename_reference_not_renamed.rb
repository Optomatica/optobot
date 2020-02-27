class RenameReferenceNotRenamed < ActiveRecord::Migration[5.1]
  def change
    rename_column :conditions, :dialogue_sequence_id, :arc_id
    rename_column :conditions, :requirement_id, :variable_id
    rename_column :user_chatbot_sessions, :requirement_id, :variable_id
    rename_column :user_data, :requirement_id, :variable_id
    rename_column :dialogues, :account_id, :project_id
    rename_column :user_projects, :account_id, :project_id
  end
end
