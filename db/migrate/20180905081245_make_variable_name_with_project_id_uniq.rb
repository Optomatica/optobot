class MakeVariableNameWithProjectIdUniq < ActiveRecord::Migration[5.1]
  def change
    remove_index :variables, name: "index_variables_on_name"
    add_index :variables, [:name, :project_id],     unique: true
    remove_index :dialogues, name: "index_dialogues_on_tag"
    add_index :dialogues, [:tag, :project_id],     unique: true
  end
end
