module ActionsHelper
  # defining an action like (action) delete_user_data(...variable_names...)
  def delete_user_data(variables_user_data)
    variables_user_data.each{|ud| ud.is_a?(ActiveRecord::Base) ? us.destroy : ud.destroy_all}
  end
end
