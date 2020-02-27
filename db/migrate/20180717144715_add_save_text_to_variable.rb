class AddSaveTextToVariable < ActiveRecord::Migration[5.1]
  def change
    add_column :variables, :save_text, :boolean, default: false
  end
end
