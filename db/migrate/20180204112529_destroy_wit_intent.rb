class DestroyWitIntent < ActiveRecord::Migration[5.0]
  def up
    drop_table :wit_intents
  end
  def down
    create_table :wit_intents do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
