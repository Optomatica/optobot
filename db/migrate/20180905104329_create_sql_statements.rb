class CreateSqlStatements < ActiveRecord::Migration[5.1]
  def change
    create_table :sql_statements do |t|
      t.json :object_content, null: false
      t.references :project, null: false
      t.integer :version, default: 1, null: false
      t.integer :sql_method, null: false
      t.string :object_class, null: false

      t.timestamps
    end
  end
end
