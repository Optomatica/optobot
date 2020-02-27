class MakeSearchFasterInOptionAndResponses < ActiveRecord::Migration[5.1]
  def change
    change_column :responses, :response_owner_type, :string, null: false, :limit => 20
    add_index :responses, [:response_owner_id, :response_owner_type]
    change_column :options, :option_owner_type, :string, null: false, :limit => 20
    add_index :options, [:option_owner_id, :option_owner_type]
  end
end
