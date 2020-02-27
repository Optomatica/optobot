class ChangeColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :variables, :key, :name
    add_index :variables, :name, unique: true
  end
end
