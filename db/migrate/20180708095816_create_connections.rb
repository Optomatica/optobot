class CreateConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.string :connection_value
      t.integer :connection_type
      t.references :user_project

      t.timestamps
    end
  end
end
