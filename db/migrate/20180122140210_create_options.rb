class CreateOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :options do |t|
      t.string :value
      t.integer :dialogue_id, null: false

      t.timestamps
    end
  end
end
