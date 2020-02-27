class CreateParameters < ActiveRecord::Migration[5.0]
  def change
    create_table :parameters do |t|
      t.string :entity, null: false
      t.string :value
      t.integer :dialogue_id, null: false
      t.float :min
      t.float :max

      t.timestamps
    end
  end
end
