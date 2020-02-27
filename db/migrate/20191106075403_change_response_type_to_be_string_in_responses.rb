class ChangeResponseTypeToBeStringInResponses < ActiveRecord::Migration[5.1]
  def change
      change_column :responses, :reponse_type, :string
  end
end
