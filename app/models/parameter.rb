class Parameter < ApplicationRecord
  has_one :condition

  validates :value, absence: true, if: :has_min_or_max
  validates :min, absence: true, if: :value
  validates :max, absence: true, if: :value

  after_destroy :destroy_condition

  def export
    self.attributes.except!("id", "created_at", "updated_at", "dialogue_id", "project_id")
  end

  private
  def has_min_or_max
    self.min || self.max
  end

  def destroy_condition
    self.condition.destroy if self.condition && self.condition.option.nil?
  end
end
