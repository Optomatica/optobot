class AddQaEngEndpointToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :qa_engine_endpoint, :string
  end
end
