class AddTmpParamsColumnToConnection < ActiveRecord::Migration[5.1]
  def change
    add_column :connections, :tmp_params, :json
  end
end
