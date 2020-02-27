class RenameResponseType < ActiveRecord::Migration[5.1]
  def change
    rename_column :responses, :reponse_type, :response_type
  end
end
