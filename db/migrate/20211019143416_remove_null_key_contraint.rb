class RemoveNullKeyContraint < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:responses, :response_owner_id, true)
    change_column_null(:intents, :dialogue_id, true)
  end
end
