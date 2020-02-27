class RemoveResponseType < ActiveRecord::Migration[5.1]
  def change
    remove_column :responses, :response_type
  end
end
