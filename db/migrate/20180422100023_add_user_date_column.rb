class AddUserDateColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :basic_data, :json, default:{}
  end
end
