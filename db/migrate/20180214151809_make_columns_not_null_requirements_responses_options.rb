class MakeColumnsNotNullRequirementsResponsesOptions < ActiveRecord::Migration[5.0]
  def up
    change_column :requirements, :dialogue_id, :integer, null: false
    change_column :responses, :response_owner_id, :integer, null: false
    change_column :responses, :response_owner_type, :string, null: false
  end
  def down
    change_column :requirements, :dialogue_id, :integer
    change_column :responses, :response_owner_id, :integer
    change_column :responses, :response_owner_type, :string
  end
end
