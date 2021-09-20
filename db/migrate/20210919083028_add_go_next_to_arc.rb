class AddGoNextToArc < ActiveRecord::Migration[5.1]
  def change
    add_column :arcs, :go_next, :boolean, default: true
  end
end
