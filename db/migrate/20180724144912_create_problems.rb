class CreateProblems < ActiveRecord::Migration[5.1]
  def change
    create_table :problems do |t|
      t.integer :problem_type
      t.references :chatbot_message, null: false
      t.references :project, null: false

      t.timestamps
    end
    add_reference :chatbot_messages, :dialogue
  end
end
