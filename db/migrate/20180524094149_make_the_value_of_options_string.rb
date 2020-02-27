class MakeTheValueOfOptionsString < ActiveRecord::Migration[5.1]
  def change
    change_column :options, :value, :string, null: true, default: nil
  end
end
