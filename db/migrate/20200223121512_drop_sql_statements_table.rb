class DropSqlStatementsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :sql_statements
  end
end
