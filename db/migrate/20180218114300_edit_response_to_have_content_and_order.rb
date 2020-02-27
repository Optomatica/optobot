class EditResponseToHaveContentAndOrder < ActiveRecord::Migration[5.0]
  def change
    remove_column :responses, :text, :string
    remove_column :responses, :image, :string
    remove_column :responses, :video, :string
    add_column :responses, :order, :integer, null: false, default: 0
  end
end
