class AddSaveNeededToRequirements < ActiveRecord::Migration[5.1]
  def change
    add_column :requirements, :save_needed, :boolean, default: false
  end
end
