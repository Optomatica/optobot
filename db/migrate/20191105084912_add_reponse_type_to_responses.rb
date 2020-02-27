class AddReponseTypeToResponses < ActiveRecord::Migration[5.1]
  def change
    add_column :responses, :reponse_type, :integer , default: true , null:false
  end
end
