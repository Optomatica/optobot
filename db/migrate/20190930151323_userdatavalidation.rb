class Userdatavalidation < ActiveRecord::Migration[5.1]
  def change
    add_column :variables, :is_valid, :boolean , default: true
  end
end
