class AddRequirementToCondition < ActiveRecord::Migration[5.1]
  def change
    add_reference :conditions, :requirement
  end
end
