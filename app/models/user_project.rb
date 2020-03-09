class UserProject < ApplicationRecord
  enum role: [:admin,  :author, :moderator, :editor, :subscriber]
  belongs_to :project
  belongs_to :user, optional: true
  belongs_to :user_chatbot_session, optional: true, dependent: :destroy
  has_many :chatbot_messages, dependent: :destroy
  has_many :user_data, dependent: :destroy
  has_many :variables, through: :user_data
  has_many :connections, dependent: :destroy

  def delete_cached_user_data
    ud = self.user_data.joins(:variable).where("variables.storage_type = ?", Variable.storage_types["in_cache"])
    ud.destroy_all
    ud = self.user_data.joins(:variable).where("variables.storage_type = ?", Variable.storage_types["timeseries_in_cache"])
    ud.update_all(expired: true)
  end

  def delete_session_user_data
    ud = self.user_data.joins(:variable).where("variables.storage_type = ?", Variable.storage_types["in_session"])
    ud.destroy_all
  end

  def delete_expired_data
    p "in delete_expired_data"
    ud =  self.user_data.joins(:variable).where("(extract(day from current_date-user_data.updated_at)*24) + 
      extract(hour from current_date-user_data.updated_at) + 
      extract(min from current_date-user_data.updated_at)  >= variables.expire_after" , Variable.storage_types["timeseries"])
    ud.destroy_all
  end

end
