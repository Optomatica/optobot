class Condition < ApplicationRecord
  belongs_to :arc
  belongs_to :variable
  belongs_to :option, optional:true
  belongs_to :parameter, optional:true


  def self.get_conditions_by(parent_id, children_ids)
    conditions = self.joins(:arc).where("arcs.parent_id = ? and arcs.child_id in (?)", parent_id, children_ids).select("conditions.*")
    return conditions
  end

  def export
		tmp_parameter = self.parameter.export unless self.parameter.nil?
		self.attributes.except!("id", "created_at", "updated_at", "arc_id", "parameter_id").merge({
			parameter: tmp_parameter
		})
  end

  def import(condition_association_data, dialogues_and_arcs_data)
		condition_association_data.each do |condition|
			tmp = {
        parameter_id: (condition[:parameter] ? Parameter.create!(condition[:parameter]) : nil),
        variable_id: dialogues_and_arcs_data[:dialogues].values.find{|d| d[:variables][condition[:variable_id]][:new_id]},
        option_id: dialogues_and_arcs_data[:dialogues].values.find{|d| d[:variables][condition[:variable_id]][:options][condition[:option_id]][:new_id]}
      }
			self.conditions.create!(tmp)
		end
  end
end
