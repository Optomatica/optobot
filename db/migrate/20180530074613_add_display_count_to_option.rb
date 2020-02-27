class AddDisplayCountToOption < ActiveRecord::Migration[5.1]
  def change
    add_column :options, :display_count, :integer
  end
end
