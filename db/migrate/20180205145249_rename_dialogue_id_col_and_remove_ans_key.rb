class RenameDialogueIdColAndRemoveAnsKey < ActiveRecord::Migration[5.0]
  def change
    rename_column :responses, :dialogue_id, :requirement_id
    remove_column :parameters, :ans_key, :string
  end
end
