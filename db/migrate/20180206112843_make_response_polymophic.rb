class MakeResponsePolymophic < ActiveRecord::Migration[5.0]
  def change
    rename_column :responses, :requirement_id, :need_response_id
    add_column :responses, :need_response_type, :string
  end
end
