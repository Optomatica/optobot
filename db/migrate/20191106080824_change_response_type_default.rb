class ChangeResponseTypeDefault < ActiveRecord::Migration[5.1]
  def change
    change_column :responses, :response_type, :string, :default => "response"
  end
end
