class RenameIntentId < ActiveRecord::Migration[5.0]
  def change
    rename_column :contexts, :intent_id, :wit_intent
  end
end
