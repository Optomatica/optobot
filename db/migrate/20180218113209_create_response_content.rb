class CreateResponseContent < ActiveRecord::Migration[5.0]
  def change
    create_table :response_contents do |t|
      t.column :content, :json, null: false
      t.column :content_type, :integer, null: false, default: 0
      t.column :response_id, :integer, null: false

      t.timestamps
    end
  end
end
