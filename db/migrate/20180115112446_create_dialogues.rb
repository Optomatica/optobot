class CreateDialogues < ActiveRecord::Migration[5.0]
  def change
    create_table :dialogues do |t|
      t.integer :context_id

      t.timestamps
    end
  end
end
