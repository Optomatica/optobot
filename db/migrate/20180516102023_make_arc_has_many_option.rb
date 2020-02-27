class MakeArcHasManyOption < ActiveRecord::Migration[5.1]
  def change
    remove_column :dialogue_sequences, :option_id
    add_column :options, :dialogue_sequence_id, :integer
  end
end
