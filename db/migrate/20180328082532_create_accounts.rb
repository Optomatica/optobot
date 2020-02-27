class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.integer :admin_user_id

      t.timestamps
    end
  end
end
