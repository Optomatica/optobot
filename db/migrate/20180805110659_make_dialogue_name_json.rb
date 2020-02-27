class MakeDialogueNameJson < ActiveRecord::Migration[5.1]
  def change
    Dialogue.find_each do |dialogue|
      dialogue.name = {en: dialogue.name}.to_json
      dialogue.save!
    end
    change_column :dialogues, :name, :json, using: "name::json"
  end
end
