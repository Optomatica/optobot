class RenameNeedResponse < ActiveRecord::Migration[5.0]
  def change
    rename_column :responses, :need_response_id, :response_owner_id
    rename_column :responses, :need_response_type, :response_owner_type
  end
end
