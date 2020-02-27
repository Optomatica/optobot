class EditColumnValueInOptions < ActiveRecord::Migration[5.0]
  def up
    change_column :options, :value, :string, null: false
  end
  def down
    change_column :options, :value, :string
  end
end
