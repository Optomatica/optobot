class AddReferenceToContext < ActiveRecord::Migration[5.1]
  def change
    add_reference :contexts, :project
  end
end
