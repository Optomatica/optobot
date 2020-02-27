class MakeUserIdAcceptNilInUserProject < ActiveRecord::Migration[5.1]
  def change
    change_column :user_projects, :user_id, :bigint, null: true
  end
end
