class Condition < ApplicationRecord
  belongs_to :arc
  belongs_to :variable
  belongs_to :option, optional: true
  belongs_to :parameter, optional: true, dependent: :destroy

  def self.get_conditions_by(parent_id, children_ids)
    self.joins(:arc).where("arcs.parent_id = ? and arcs.child_id in (?)", parent_id, children_ids).select("conditions.*")
  end

  def export
    exempted_keys = ["id", "created_at", "updated_at", "arc_id", "parameter_id"]
    exported_parameter = self.parameter.export unless self.parameter.nil?
    self.attributes.except(*exempted_keys).merge(parameter: exported_parameter)
  end

end
