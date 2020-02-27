class AddNameToDialogue < ActiveRecord::Migration[5.0]
  def change
    add_column :dialogues, :name, :string, null: false
  end
end
