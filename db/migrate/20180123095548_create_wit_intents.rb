class CreateWitIntents < ActiveRecord::Migration[5.0]
  def change
    create_table :wit_intents do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
