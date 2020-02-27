class ModifyParameters < ActiveRecord::Migration[5.1]
  def change
    remove_column :parameters, :entity
  end
end
