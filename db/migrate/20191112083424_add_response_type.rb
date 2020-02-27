class AddResponseType < ActiveRecord::Migration[5.1]
  def change
    add_column :responses, :reponse_type, :integer , default: 0 , null:false
  end
end
