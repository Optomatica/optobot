class CreateUserData < ActiveRecord::Migration[5.1]
  def change
    create_table :user_data do |t|
      t.references :user_project, null: false
      t.references :requirement, null: false
      t.references :option
      t.string :value
      t.string :unit

      t.timestamps
    end
  end
end
