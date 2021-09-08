module ActionsHelper
  include APICalls
  # defining an action like (action) delete_user_data(...variable_names...)
  def delete_user_data(*variables_user_data)
    variables_user_data.each{|ud| ud.is_a?(ActiveRecord::Base) ? us.destroy : ud.destroy_all}
  end

  def delete_latest_user_data(user_project)
    user_project.user_data.last.destroy!
  end

  def handover_to_human(user_project)
    url = "https://graph.facebook.com/v2.6/me/pass_thread_control?access_token=#{user_project.project.facebook_page_access_token}"
    user_project.connections.each do |connection|
      if connection.connection_type == 'facebook'
        body = {
          "recipient": {"id": connection.connection_value},
          "target_app_id": 263902037430900,
          "metadata": "Conversation handed to page index"
        }
        APICalls.postRequest(url, nil, body.to_json)
      end
    end
  end
end
