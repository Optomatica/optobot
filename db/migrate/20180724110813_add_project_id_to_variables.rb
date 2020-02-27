class AddProjectIdToVariables < ActiveRecord::Migration[5.1]
  def change
    change_column :variables, :dialogue_id, :integer, null: true
    add_reference :variables, :project 
    Variable.reset_column_information
    Variable.find_each {|variable|
      variable.project_id = variable.dialogue.project_id
      variable.save!
    }
  end
end
