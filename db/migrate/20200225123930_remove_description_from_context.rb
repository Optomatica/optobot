class RemoveDescriptionFromContext < ActiveRecord::Migration[5.1]
  def change
    remove_column :contexts, :description
  end
end
