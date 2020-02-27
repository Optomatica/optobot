class ArcsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_arc, only: [:show, :list_variables]
  before_action :can_access_or_edit?

  api :GET, '/arcs/:id'
  def show
    conditions = []
    @arc.conditions.each do |x|
      condition = { id: x.id, parameter: x.parameter, option: x.option }
      conditions.push condition
    end

    render json: { parent: @arc.parent, conditions: conditions, child: @arc.child }
  end

  api :GET, '/arcs/:id/list_variables'
  def list_variables
    p @arc
    project = @arc.child.project
    context_id = @arc.child.context_id

    all_variables = Variable.joins(:dialogue)
                       .where('dialogues.project_id = ?', project.id)
    all_variables_with_dialogues = all_variables.joins(:dialogue)
                                      .where('dialogues.context_id = ?', context_id)

    context_variables = get_variables_with_options(all_variables_with_dialogues)
    parent_variables = get_variables_with_options(@arc.parent.variables) if @arc.parent_id
    rest_variables = get_variables_with_options(all_variables) - context_variables

    context_variables -= parent_variables if @arc.parent_id
    render json: { parent_variables: parent_variables, context_variables: context_variables,
                   rest_variables: rest_variables }
  end

  private

  def set_arc
    @arc = Arc.find_by_id(params[:id])
    render json: 'Arc not exist.', status: :not_found if @arc.nil?
  end

  def arc_params
    params.permit(:parent_id, :child_id)
  end

  def can_access_or_edit?
    project_id = @arc.child.project_id
    projects_count = current_user.user_projects.where("project_id = ? and role = 0
                                                or role = 1", project_id).count

    err_msg = "This arc doesn't exist or it isn't yours!"
    render json: err_msg, status: :bad_request if projects_count.zero?
  end

  def get_variables_with_options(vars)
    vars.map { |v| { id: v.id, name: v.name, options: map_options(v.options) } }
  end

  def map_options(options)
    options.map do |o|
      response = o.response.response_contents.first
      { id: o.as_json['id'], response: response.nil? ? {} : response['content'] }
    end
  end
end
