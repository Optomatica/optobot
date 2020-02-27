class CreateDialogueSequences < ActiveRecord::Migration[5.0]
  def change
    create_table :dialogue_sequences do |t|
      t.integer :parent_id
      t.integer :child_id
     
      t.timestamps
    end
    add_index :dialogue_sequences, :parent_id
    add_index :dialogue_sequences, :child_id
    add_index :dialogue_sequences, [:parent_id, :child_id], unique: true

  end
end