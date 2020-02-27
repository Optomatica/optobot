class AddColumnsToRequirements < ActiveRecord::Migration[5.0]
  def change
    add_column :requirements, :dialogue_id, :integer
  end
end
