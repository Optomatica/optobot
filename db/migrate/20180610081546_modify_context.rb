class ModifyContext < ActiveRecord::Migration[5.1]
  def change
    remove_column :contexts, :wit_intent
    remove_column :contexts, :account_id
    
  end
end
