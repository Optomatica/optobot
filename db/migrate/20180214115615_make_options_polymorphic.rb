class MakeOptionsPolymorphic < ActiveRecord::Migration[5.0]
  def change
    rename_column :options, :dialogue_id, :option_owner_id
    add_column :options, :option_owner_type, :string, null: false
  end
end
