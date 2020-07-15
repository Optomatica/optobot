class RenameActionToActionsInDialogues < ActiveRecord::Migration[5.1]
  def change
    rename_column :dialogues, :action, :actions
  end
end
