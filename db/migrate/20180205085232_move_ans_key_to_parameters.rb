class MoveAnsKeyToParameters < ActiveRecord::Migration[5.0]
  def change
    remove_column :dialogues, :ans_key, :string
    add_column :parameters, :ans_key, :string
  end
end
