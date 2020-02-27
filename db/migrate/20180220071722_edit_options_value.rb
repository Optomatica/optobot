class EditOptionsValue < ActiveRecord::Migration[5.0]
  def change
    remove_column :options, :value, :string
    add_column :options, :value, :json, null: false, default: {}
  end
end
