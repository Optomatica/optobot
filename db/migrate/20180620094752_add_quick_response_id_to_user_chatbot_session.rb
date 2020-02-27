class AddQuickResponseIdToUserChatbotSession < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :basic_data
  end
end
