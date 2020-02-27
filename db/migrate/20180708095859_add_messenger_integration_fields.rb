class AddMessengerIntegrationFields < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :facebook_page_id, :string, :limit => 20
    add_column :projects, :facebook_page_access_token, :string
    add_index :projects, :facebook_page_id, unique: true
  end
end
