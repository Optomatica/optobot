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
    project_id = params[:project_id].to_i
    dialogue_proj_id = dialogue_id ? Dialogue.find(dialogue_id).project_id : nil

    if dialogue_proj_id != project_id
      err_msg = "That Dialogue doesn't belong to that project"
      render_bad_req_with_err_msg(err_msg) and return
    elsif project_id.nil? || role_projs_cnt(project_id).zero?
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

  def weather(city_name)
    p 'in weather given city_name = ', city_name[0]
    city = city_name.first
    acc_key = '8da14f08dc9fe885d86c975fa1620d15'
    url = "http://api.weatherstack.com/current?access_key=#{acc_key}&query=#{city}"

    uri = URI(url)
    request = Net::HTTP.get(uri)
    response = JSON.parse(request)

    (response.nil? || response['current'].nil?) ? 'error' : response['current']['temperature']
  end

  def sum(num_arr)
    num_arr.inject(0.0) { |sum, i| sum + i.to_f }
  end

  def sub(num_arr)
    num_arr.first.to_f - num_arr.last.to_f
  end

  def multiply(num_arr)
    num_arr.inject(1.0) { |product, i| product * i.to_f }
  end

  def division(num_arr)
    num_arr.first.to_f / num_arr.last.to_f
  end

  def power(num_arr)
    num_arr.first.to_f**num_arr.last.to_f
  end

  def int_division(num_arr)
    num_arr.first.to_i / num_arr.last.to_i
  end

  def less_than(num_arr)
    num_arr.first.to_i < num_arr.last.to_i ? "true" : "false"
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
