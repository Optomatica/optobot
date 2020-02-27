class MakeVariableOfConditionNotAcceptNull < ActiveRecord::Migration[5.1]
  def change
    change_column :conditions, :variable_id, :bigint, null: false
  end
end
