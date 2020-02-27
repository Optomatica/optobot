class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :is_admin_or_author?, only: [:create, :list]
  before_action :set_context, only: [:show, :get_dialogues_of_context, :update, :destroy]
  before_action :is_context_admin_or_author?, only: [:show, :get_dialogues_of_context, :update, :destroy]

  api :GET, '/contexts/:id/show'
  description "show context"
  param :id, :number, required: true
  def show
    render :json => @context
  end

  api :GET, '/contexts/list'
  description "list all contexts in a project"
  param :project_id, :number, required: true
  def list
    project = Project.find_by_id(params[:project_id])
    render :json => project.contexts
  end

  api :GET, '/contexts/:id/has_dialogues'
  description "list all dialogues of the context"
  param :id, :number, required: true
  def get_dialogues_of_context
    render :json => {:context => @context, :dialogues => @context.dialogues}
  end

  api :POST, '/contexts/create or /contexts'
  description "add new context"
  param :project_id, :number, required: true
  param :name, String
  def create
    if params[:name].nil? or params[:name].blank?
      render body: "context name is missing or blank!", status: :bad_request and return
    end
    @context = Context.new(context_params.merge({project_id: params[:project_id]}))
    if @context.save
      render json: @context, status: :created
    else
      render json: @context.errors, status: :unprocessable_entity
    end
  end

  api :PUT, '/contexts/:id/update or /contexts/:id'
  description "update context"
  param :id, :number, required: true
  param :name, String
  def update
    if params[:name].nil? or params[:name].blank?
      render body: "name should not be blanked", status: :bad_request and return
    end
    if @context.update_attributes(name: params[:name])
      render json: @context, status: :ok
    else
      render json: @context.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/contexts/:id/destroy or /contexts/:id'
  description "delete context"
  param :id, :number, required: true
  def destroy
    tmp = @context
    @context.destroy
    render json: {body: 'Context was successfully destroyed.', destroyed_parameter: tmp }
  end

  private
    def set_context
      @context = Context.find_by_id(params[:id])
      if @context.nil?
        render json: 'Context not exist.', status: 404
      end
    end

    def is_context_admin_or_author?
      unless @context.is_user_admin_or_author(current_user)
        render body: nil, status: :unauthorized and return
      end
    end

    def context_params
      params.permit(:project_id, :name)
    end
end
