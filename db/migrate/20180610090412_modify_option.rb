class ModifyOption < ActiveRecord::Migration[5.1]
  def change
    new_options = []
    Dialogue.find_each do |dialogue|
      options = Option.where(option_owner_id: dialogue.id, option_owner_type: "Dialogue")
      if options.present?
        v = dialogue.variables.create!(key: "#{dialogue.id+100}")
        options.each do |o|
          new_options << {option: option, variable_id: v.id}
        end
        dialogue.responses.each do |r|
          r.response_owner = v
          r.save!
        end

      end
    end
    add_column :options, :unit, :string
    change_column :options, :display_count, :integer, default: 1
    rename_column :options, :option_owner_id, :variable_id
    remove_column :options, :option_owner_type

    Variable.reset_column_information
    new_options.each do |o|
      option = Option.find o[:option].id
      option.variable_id = o[:variable_id]
      option.save!
    end
  end
end
