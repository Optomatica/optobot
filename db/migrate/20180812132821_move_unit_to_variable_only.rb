class MoveUnitToVariableOnly < ActiveRecord::Migration[5.1]
  def change
    add_column :variables, :unit, :string

    Variable.reset_column_information
    UserDatum.find_each do |user_datum|
      user_datum.variable.unit = user_datum.unit
    end
    Option.find_each do |option|
      option.variable.unit = option.unit
    end
    Parameter.find_each do |parameter|
      parameter.condition.variable.unit = parameter.unit
    end
    remove_column :parameters, :unit
    remove_column :options, :unit
    remove_column :user_data, :unit
  end
end
