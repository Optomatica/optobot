class ModifyDialogueSequence < ActiveRecord::Migration[5.1]
  def change
    rename_table :dialogue_sequences, :arcs
    add_column :arcs, :is_and, :boolean, :default => true
  end
end
