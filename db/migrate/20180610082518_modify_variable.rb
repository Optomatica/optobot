class ModifyVariable < ActiveRecord::Migration[5.1]
  def change
    rename_table :requirements, :variables
    rename_column :variables, :ans_key, :key
    rename_column :variables, :wit_entities, :possible_values
    remove_column :variables, :name
    remove_column :variables, :save_needed
    add_column :variables, :expire_after, :integer
    add_column :variables, :storage_type, :integer, default: :normal
    add_column :variables, :source, :integer, default: :collected
    add_column :variables, :allow_writing, :boolean, default: true
    add_column :variables, :entity, :string
    add_column :variables, :allowed_range, :json
    add_column :variables, :fetch_info, :json
    Variable.reset_column_information
    Variable.find_each {|variable|
      if variable.possible_values and variable.possible_values.include? "distance"
        variable.entity = "distance"
        variable.possible_values = []
      elsif variable.possible_values and variable.possible_values.include? "number"
        variable.entity = "number"
        variable.possible_values = []
      elsif (variable.possible_values and variable.possible_values.include? "yes") || (variable.possible_values and variable.possible_values.include? "no")
        variable.entity = "yes_or_no"
      else
        variable.entity = "intent"
      end
      variable.save!
    }
  end
end
