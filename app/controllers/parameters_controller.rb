class ParametersController < ApplicationController
  before_action :authenticate_user!
  before_action :is_admin_or_author?
  before_action :can_access_or_edit_arc_relatives?
  before_action :set_parameter, only: [:show, :update, :destroy]
  before_action :set_condition, only: [:create, :destroy]
  before_action :is_arc_own_me?, only: [:show, :update, :destroy]

  api :POST, '/arcs/:arc_id/parameters/create or /arcs/:arc_id/parameters'
  description "add new parameters for the current dialogue"
  param :arc_id, :number, required: true, allow_nil: false
  param :condition_id, :number, required: false, allow_nil: false
  param :variable_id, :number, required: false, allow_nil: false, desc: "required = true if no condition id"
  param :value, String, desc: "required if and only if params(min and max) are not exist"
  param :min, :number, desc: "required with param(max) if and only if param(value) is not exist"
  param :max, :number, desc: "required with param(min) if and only if param(value) is not exist"
  def create
    if parameter_params[:value].nil? or parameter_params[:value].blank?
      if parameter_params[:min].nil? or parameter_params[:max].nil?
        render body: "value or (min and max) are required!", status: :bad_request and return
      end
    end
    @parameter = Parameter.create!(parameter_params)
    begin
      to_render = nil
      ActiveRecord::Base.transaction do
        if params[:condition_id].nil?
          condition = Condition.create!(arc_id: params[:arc_id], parameter_id: @parameter.id, variable_id: params[:variable_id])
        else
          @condition.parameter_id = @parameter.id
          @condition.save!
        end
      end
      render json: {parameter: @parameter, warning: to_render}, status: :created
    rescue  ActiveRecord::ActiveRecordError
      ActiveRecord::Rollback
      render json: @parameter.errors, status: :unprocessable_entity
    end
  end

  api :PUT, '/arcs/:arc_id/parameters/:id/update or /arcs/:arc_id/parameters/:id'
  description "update parameter"
  param :id, :number, required: true
  param :arc_id, :number, required: true, allow_nil: false
  param :value, String, desc: "don't add if params(min and max) are exist"
  param :min, :number, desc: "don't add if param(value) is exist"
  param :max, :number, desc: "don't add if param(value) is exist"
  def update
    if !parameter_params[:value].nil? and parameter_params[:value].blank?
      if parameter_params[:min].nil? or parameter_params[:max].nil?
        render body: "value or (min and max) are required!", status: :bad_request and return
      else
        params[:value]=nil
      end
    end
    if @parameter.update(parameter_params)
      render json: @parameter, status: :ok
    else
      render json: @parameter.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/arcs/:arc_id/parameters/:id/destroy or /arcs/:arc_id/parameters/:id'
  description "delete parameter by id"
  param :id, :number, required: true
  param :arc_id, :number, required: true, allow_nil: false
  def destroy
    tmp = @parameter
    @parameter.destroy
    render json: {body: 'Parameter was successfully destroyed.', destroyed_parameter: tmp }
  end

  private
    def set_parameter
      @parameter = Parameter.find_by_id(params[:id])
      if @parameter.nil?
        render json: 'Parameter not exist.', status: 404
      end
    end

    def set_condition
      return if params[:condition_id].nil?
      @condition = Condition.find_by_id(params[:condition_id])
      if @condition.nil?
        render json: 'Condition not exist.', status: 404
      end
    end

    def parameter_params
      params.permit(:project_id , :value, :min, :max)
    end

    def is_arc_own_me?
      if Parameter.find(params[:id]).condition.arc.id != params[:arc_id].to_i
        render body: "this arc doesn't have this parameter!", status: :unprocessable_entity
      end
    end
end
