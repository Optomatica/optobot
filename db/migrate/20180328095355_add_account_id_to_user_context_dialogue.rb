class AddAccountIdToUserContextDialogue < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :account_id, :integer, null: false
    add_column :contexts, :account_id, :integer, null: false
    add_column :dialogues, :account_id, :integer, null: false

  end
end
