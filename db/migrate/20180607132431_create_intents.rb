class CreateIntents < ActiveRecord::Migration[5.1]
  def change
    create_table :intents do |t|
      t.references :dialogue, null:false
      t.string :value, null:false

      t.timestamps
    end
    Intent.reset_column_information
    Context.find_each do |context|
      context.dialogues.each do |dialogue|
        Intent.create!(value: context.wit_intent, dialogue_id: dialogue.id)
      end
    end
  end
end
