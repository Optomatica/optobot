class RemoveIsValidFromVariable < ActiveRecord::Migration[5.1]
  def change
    remove_column :variables, :is_valid
  end
end
