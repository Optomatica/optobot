class RemoveDialogueSequenceFromOptionsAndParameters < ActiveRecord::Migration[5.1]
  def change
    remove_column :options, :dialogue_sequence_id, :integer
    remove_column :parameters, :dialogue_sequence_id, :integer
  end
end
