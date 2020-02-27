class AddProdProjectId < ActiveRecord::Migration[5.1]
  def change
    if Project.column_names.include?("prod_project_id")
      rename_column :projects, :prod_project_id, :test_project_id
    else
      add_column :projects, :test_project_id, :bigint
      add_index :projects, :test_project_id
    end 
  end
end
