class AddNlpApiToken < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :nlp_api_token, :json, null: false, default: {}
  end
end
