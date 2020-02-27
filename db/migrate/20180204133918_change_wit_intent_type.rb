class ChangeWitIntentType < ActiveRecord::Migration[5.0]
  def up
    change_column :contexts, :wit_intent, :string
  end
  def down
    remove_column :contexts, :wit_intent
    add_column :contexts, :wit_intent, :integer
  end
end
