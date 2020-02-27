class AddAnsKeyInDialogues < ActiveRecord::Migration[5.1]
  def change
    add_column :dialogues, :ans_key, :string
    add_column :dialogues, :wit_entities, :json
  end
end
