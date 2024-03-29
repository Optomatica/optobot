module MainHelper

  def set_lang
    @lang = params[:language] || 'en'
  end

  def map_lang(arr, attribute = 'name')
    return nil if arr.nil?

    arr.map do |w|
      lang = w[attribute][@lang]
      w[attribute] = lang.nil? ? w[attribute][w[attribute].keys.first] : lang
    end
  end

  def get_lang(attribute, lang)
    attribute[lang].nil? ? attribute[attribute.keys.first] : attribute[lang]
  end

  def same_user?
    is_same = (current_user.id == params[:user_id].to_i)
    render body: nil, status: :unauthorized and return unless is_same
  end


  def is_admin?
    project_id = params[:project_id] || params[:id]
    admin_projs_cnt = current_user.user_projects.where(project_id: project_id,
                                                       role: 'admin').count
    err_msg = 'You must be the admin of the project to do this action.'

    admin_projs_cnt.zero? ? render_bad_req_with_err_msg(err_msg) : true
  end

  def is_admin_or_author?
    project_id = params[:project_id]
    err_msg = 'You must be the admin or author of the project to do this action.'
    render_bad_req_with_err_msg(err_msg) if role_projs_cnt(project_id).zero?
  end

  def can_access_or_edit_dialogue_relatives?
    dialogue_id = params[:dialogue_id]
    project_id = dialogue_id ? Dialogue.find(dialogue_id).project_id : nil

    if project_id.nil? || role_projs_cnt(project_id).zero?
      err_msg = 'You are not authorized to do this action.'
      render_bad_req_with_err_msg(err_msg)
    end

  end

  def can_access_or_edit_arc_relatives?
    arc = Arc.find_by_id(params[:arc_id])
    err_msg = "This arc doesn't exist"
    render_bad_req_with_err_msg(err_msg) and return if arc.nil?

    project_id = arc.child.project_id
    err_msg = "This arc doesn't exist or it isn't yours!"
    render_bad_req_with_err_msg(err_msg)if role_projs_cnt(project_id).zero?
  end

  private

  def role_projs_cnt(project_id)
    current_user.user_projects.where('project_id = ? and role = 0 or role = 1',
                                     project_id).count
  end

  def render_bad_req_with_err_msg(err_msg)
    render body: err_msg, status: :bad_request
  end
end
