class AddGetStartedNodeToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :get_started_node, :boolean, default: false
  end
end
