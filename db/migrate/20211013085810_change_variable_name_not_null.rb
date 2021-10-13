class ChangeVariableNameNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column :variables, :name, :string, null: false
  end
end
