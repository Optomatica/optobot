class CreateRequirements < ActiveRecord::Migration[5.0]
  def change
    create_table :requirements do |t|
      t.string :name
      t.json :wit_entities
      t.string :ans_key

      t.timestamps
    end
  end
end
