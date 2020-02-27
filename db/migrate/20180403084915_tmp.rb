class Tmp < ActiveRecord::Migration[5.1]
  def up
    remove_index :users, name: :index_users_on_email
  end
  def down
    add_index :users, [:email], unique: true
  end
end
