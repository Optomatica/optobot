class VariablesController < ApplicationController
  before_action :authenticate_user!
  before_action :can_access_or_edit_dialogue_relatives?
  before_action :set_variable, only: [:show, :update, :destroy]
  before_action :is_dialogue_own_me?, only: [:show, :update, :destroy]
  before_action :is_project_own_me?, only: [:show, :update, :destroy]
  before_action :is_valid_storage_type?, only: [:create, :update]
  before_action :is_valid_source?, only: [:create, :update]

  api :GET, '/dialogues/:dialogue_id/variables/:id/show'
  description "show variable of the current dialogue with its messages and options"
  param :id, :number, required: true
  param :project_id, :number, required: true
  param :dialogue_id, :number, required: true
  def show
    responses = @variable.responses.map do |res|
      res.as_json.merge(res.response_contents.first.as_json.except('id'))
    end

    options = @variable.options.map do |opt|
      resp_cont = opt.response.response_contents.first.as_json&.except('id')
      resp = opt.response.as_json.merge(resp_cont || {})

      opt.as_json.merge(response: resp)
    end

    render json: { variable: @variable, responses: responses, options: options }
  end

  api :GET, '/dialogues/:dialogue_id/variables/list'
  description "show variables of the current dialogue with its messages and options"
  param :id, :number, required: true
  param :project_id, :number, required: true
  param :dialogue_id, :number, required: true
  def list
    variables = Variable.where(project_id: variable_params[:project_id])

    vars_json = variables.map do |var|
      options = var.options.map do |opt|
        resp = opt.response.response_contents.first

        { id: opt.as_json['id'], response: resp.nil? ? {} : resp['content'] }
      end

      { variable: var, options: options }
    end

    render json: vars_json
  end


  api :POST, '/dialogues/:dialogue_id/variables/create or /variables/create'
  description "add new variable for the current dialogue"
  param :dialogue_id, :number
  param :project_id, :number, required: true
  param :name, String
  param :expire_after, :number
  param :storage_type, String, disc: "normal, timeseries, in_session , timeseries_in_cache or in_cache"
  param :source, String, disc: "collected, fetched or provided"
  param :allow_writing, :boolean
  param :entity, String
  param :possible_values, Array, of: String
  param :allowed_range, Hash, disc: "with keys 'min' and 'max'"
  param :fetch_info, Hash
  def create
    puts variable_params.to_json
    @variable = Variable.new(variable_params)

    saved = @variable.save
    render json: @variable.errors, status: :unprocessable_entity unless saved

    render json: @variable, status: :created
  end

  api :PUT, '/dialogues/:dialogue_id/variables/:id/update or /variables/:id/update'
  description "update variable"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true, allow_nil: false
  param :project_id, :number, required: true
  param :name, String
  param :expire_after, :number
  param :storage_type, String, disc: "normal, timeseries, in_session, timeseries_in_cache or in_cache"
  param :source, String, disc: "collected, fetched or provided"
  param :allow_writing, :boolean
  param :entity, String
  param :possible_values, Array, of: String
  param :allowed_range, Hash, disc: "with keys 'min' and 'max'"
  param :fetch_info, Hash
  def update
    if @variable.update(variable_params)
      render json: @variable, status: :ok
    else
      render json: @variable.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/dialogues/:dialogue_id/variables/:id/destroy or /variables/:id/destroy'
  description "delete variable by id"
  param :id, :number, required: true
  param :project_id, :number, required: true
  param :dialogue_id, :number, required: true, allow_nil: false
  def destroy
    res = { body: 'Variable was successfully destroyed.',
            destroyed_parameter: @variable }

    @variable.destroy
    render json: res
  end

  private

  def set_variable
    @variable = Variable.find_by_id(params[:id])
    render json: 'Variable not exist.', status: 404 if @variable.nil?
  end

  def variable_params
    params.permit(:id, :dialogue_id, :name, :project_id, :expire_after,
                  :storage_type, :source, :allow_writing, :entity,
                  :possible_values,
                  :allowed_range => [:min, :max], fetch_info: [:url])
  end

  def is_dialogue_own_me?
    dialogue_id = variable_params[:dialogue_id]
    vars = Variable.where(id: params[:id], dialogue_id: dialogue_id) if dialogue_id

    render "this dialogue doesn't have this variable!", status: :unprocessable_entity if vars.length.zero?
  end

  def is_project_own_me?
    project_id = variable_params[:project_id]
    vars = Variable.where(id: params[:id], project_id: project_id) if project_id

    render "this project doesn't have this variable!", status: :unprocessable_entity if vars.length.zero?
  end

  def is_valid_storage_type?
    return if params[:storage_type].nil?

    storage_type = Variable.storage_types[params[:storage_type]]
    render body: nil, status: :bad_request and return if storage_type.nil?
  end

  def is_valid_source?
    return if params[:source].nil?

    source = Variable.sources[params[:source]]
    render body: nil, status: :bad_request and return if source.nil?
  end
end
