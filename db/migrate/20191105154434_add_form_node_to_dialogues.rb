class AddFormNodeToDialogues < ActiveRecord::Migration[5.1]
  def change
    add_column :dialogues, :form_node, :boolean , default: false
  end
end
