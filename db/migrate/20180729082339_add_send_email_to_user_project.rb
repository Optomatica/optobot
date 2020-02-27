class AddSendEmailToUserProject < ActiveRecord::Migration[5.1]
  def change
    add_column :user_projects, :send_email, :boolean, default: false
  end
end
