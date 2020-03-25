class RenameTestProjectId < ActiveRecord::Migration[5.1]
  def change
    rename_column :projects, :test_project_id, :prod_project_id
    add_column :projects, :tmp_project_id, :integer
  end
end
