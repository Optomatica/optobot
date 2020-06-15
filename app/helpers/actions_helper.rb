module ActionsHelper
  def delete_variables_user_data(user_project, *variable_names)
    variables_ids = user_project.project.variables.where(name: variable_names).ids
    user_data = user_project.user_data.where(variable_id: variables_ids)
    user_data.destroy_all
  end
end
