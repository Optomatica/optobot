class Make < ActiveRecord::Migration[5.1]
  def change
    remove_column :dialogues, :wit_entities, :string, array: true
    remove_column :requirements, :wit_entities, :string, array: true
    add_column :dialogues, :wit_entities, :string, array: true
    add_column :requirements, :wit_entities, :string, array: true
  end
end
