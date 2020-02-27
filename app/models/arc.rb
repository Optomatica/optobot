class Arc < ApplicationRecord
  belongs_to :parent, class_name: 'Dialogue', optional: true
  belongs_to :child, class_name: 'Dialogue'
  has_many :conditions, dependent: :destroy
  has_many :variables, through: :conditions
  has_many :parameters, -> { distinct }, through: :conditions #  # http://guides.rubyonrails.org/association_basics.html
  has_many :options, -> { distinct }, through: :conditions #  # http://guides.rubyonrails.org/association_basics.html

  def self.add_relations(parents_ids, children_ids)
    ActiveRecord::Base.transaction do
      arcs = []
      id_pairs = parents_ids.product children_ids
      id_pairs.each do |p|
        arcs.push Arc.create(parent_id: p.first, child_id: p.second)
      end
      return arcs
    rescue ActiveRecord::RecordNotUnique
      raise ActiveRecord::Rollback
    end

    return ActiveRecord::RecordNotUnique
  end


  def self.get_relations(parents_ids,children_ids)
    sequences = []
    begin
      id_pairs = parents_ids.product children_ids
      id_pairs.each do |p|
        sequences.push Arc.find_by(parent_id: p.first, child_id: p.second)
      end
      return sequences
    rescue ActiveRecord::RecordNotFound
      return ActiveRecord::RecordNotFound
    end
  end

  def self.remove_relations(parents_ids,children_ids)
    sequences = get_relations(parents_ids, children_ids)
    sequences.each(&:destroy) if sequences != ActiveRecord::RecordNotFound
    return sequences
  end

  def export
    conditions = { conditions: self.conditions.map(&:export) }
    self.attributes.except!('id', 'created_at', 'updated_at').merge(conditions)
  end

  def import(associations_data, dialogues_and_arcs_data)
    p associations_data
    return unless associations_data

    dialogues = dialogues_and_arcs_data[:dialogues]

    associations_data.each do |cond|
      cond_var_sym = cond[:variable_id].to_s.to_sym
      cond_opt_sym = cond[:option_id].to_s.to_sym

      param_id = cond[:parameter] ? Parameter.create!(cond[:parameter]).id : nil
      dialogue = dialogues.values.find { |d| d[:variables][cond_var_sym] }
      var = dialogue[:variables][cond_var_sym]
      var_id = var[:new_id]
      opt_id = cond[:option_id].nil? ? nil : var[:options][cond_opt_sym][:new_id]
      p 'pass'

      self.conditions.create!(parameter_id: param_id, variable_id: var_id,
                              option_id: opt_id)
    end
  end

  private_class_method :get_relations
end
