class AddExpiredToUserData < ActiveRecord::Migration[5.1]
  def change
    add_column :user_data, :expired, :boolean , default: false
  end
end
