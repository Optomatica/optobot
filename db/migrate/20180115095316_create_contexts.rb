class CreateContexts < ActiveRecord::Migration[5.0]
  def change
    create_table :contexts do |t|
      t.string :name, null: false
      t.integer :intent_id, null: false
      t.timestamps
    end
  end
end
