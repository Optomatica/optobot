class AddIdentifierToAllProjectContentTables < ActiveRecord::Migration[5.1]
  def change
    add_column :contexts,           :identifier, :bigint
    add_column :dialogues,          :identifier, :bigint
    add_column :variables,          :identifier, :bigint
    add_column :responses,          :identifier, :bigint
    add_column :response_contents,  :identifier, :bigint
    add_column :options,            :identifier, :bigint
    add_column :arcs,               :identifier, :bigint
    add_column :parameters,         :identifier, :bigint
    add_column :intents,            :identifier, :bigint
    add_column :conditions,         :identifier, :bigint
  end
end
