class AddUnitToParameters < ActiveRecord::Migration[5.1]
  def change
    add_column :parameters, :unit, :string
  end
end
