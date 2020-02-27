class UndoLocalizeDialogueNameAndAddDescriptionInContext < ActiveRecord::Migration[5.1]
  def change
    change_column :dialogues, :name, :string
    add_column :contexts, :description, :json
  end
end
