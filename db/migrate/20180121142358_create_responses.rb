class CreateResponses < ActiveRecord::Migration[5.0]
  def change
    create_table :responses do |t|
      t.string :text
      t.integer :dialogue_id
      t.string :image
      t.string :video

      t.timestamps
    end
  end
end
