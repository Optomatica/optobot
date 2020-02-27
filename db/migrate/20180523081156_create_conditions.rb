class CreateConditions < ActiveRecord::Migration[5.1]
  def change
    create_table :conditions do |t|
      t.integer :option_id
      t.integer :parameter_id
      t.integer :dialogue_sequence_id, null: false

      t.timestamps
    end
  end
end
