class AddVersionToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :version, :integer, default: 1
  end
end
