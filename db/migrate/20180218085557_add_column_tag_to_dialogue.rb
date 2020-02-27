class AddColumnTagToDialogue < ActiveRecord::Migration[5.0]
  def change
    add_column :dialogues, :tag, :string
    add_index :dialogues, :tag, unique: true
  end
end
