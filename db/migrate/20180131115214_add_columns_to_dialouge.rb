class AddColumnsToDialouge < ActiveRecord::Migration[5.0]
  def change
  	add_column :dialogues, :ans_key, :string
  	add_column :dialogues, :action, :string

  end
end
