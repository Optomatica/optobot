class AddOptionIdToDialogueSeq < ActiveRecord::Migration[5.1]
  def change
    add_column :dialogue_sequences, :option_id, :integer
    rename_column :parameters, :dialogue_id, :dialogue_sequence_id
  end
end
