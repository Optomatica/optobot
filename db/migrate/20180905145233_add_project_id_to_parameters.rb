class AddProjectIdToParameters < ActiveRecord::Migration[5.1]
  def change
    add_reference :parameters, :project
  end
end
