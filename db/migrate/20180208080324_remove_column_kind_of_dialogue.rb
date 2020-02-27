class RemoveColumnKindOfDialogue < ActiveRecord::Migration[5.0]
  def change
    remove_column :dialogues, :kind, :string
  end
end
