class AddFacebookPersonaToContext < ActiveRecord::Migration[5.1]
  def change
    add_column :contexts, :facebook_persona_id, :string
  end
end
