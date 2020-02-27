class ModifyDialogue < ActiveRecord::Migration[5.1]
  def change
    remove_column :dialogues, :ans_key
    remove_column :dialogues, :wit_entities
    remove_column :dialogues, :action
    add_column :dialogues, :action, :json
  end
end
