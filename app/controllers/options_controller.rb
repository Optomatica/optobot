class OptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :can_access_or_edit_dialogue_relatives?, except: [:add_to_condition, :remove_from_condition]
  before_action :can_access_or_edit_arc_relatives?, only: [:add_to_condition]
  before_action :set_option, only: [:update, :destroy, :remove_from_condition, :add_to_condition]
  before_action :set_condition, only: [:remove_from_condition, :add_to_condition]

  before_action :is_variable_owner?, only: [:create, :update, :destroy]

  before_action :is_option_owner?, only: [:update, :destroy]
  before_action :set_lang

  api :GET, '/dialogues/:dialogue_id/variables/:variable_id/options'
  description "list all options of current dialogue and its variables"
  param :dialogue_id, :number, required: true, allow_nil: false
  param :variable_id, :number, required: true, allow_nil: false
  def list
    dialogue = Dialogue.find_by_id(params[:dialogue_id])
    to_render = []

    dialogue.variables.each do |variable|
      to_render = Option.where(variable_id: variable.id).to_a.select{|o| !o.response.nil?}.map{|o|
        {id: o.id, response: o.response.as_json.merge(o.response.response_contents.first.nil? ? {} : o.response.response_contents.first.as_json.except("id"))}
      }
    end
    render json: to_render
  end

  api :POST, '/dialogues/:dialogue_id/variables/:variable_id/options/create'
  description "add new variable for the current dialogue"
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  param :value, String, required: true, desc: "wit value in Synonyms"
  param :display_count, :number
  def create
    @option = Option.new(option_params)
    begin
      @option.save!
      render json: @option.as_json.merge({response: Option.find(@option.id).response.as_json}), status: :created
    rescue  ActiveRecord::ActiveRecordError => e
      ActiveRecord::Rollback
      render json: e.message, status: :unprocessable_entity
    end
  end

  api :POST, '/arcs/:arc_id/options/:id/add_to_condition'
  param :id, :number, required: true
  param :arc_id, :number
  param :condition_id, :number, required: false
  def add_to_condition
    if option_params[:condition_id].nil?
      condition = Condition.create!(arc_id: option_params[:arc_id], option_id: @option.id)
      render json: condition, status: :created
    else
      @condition.option_id = @option.id
      @condition.save!
      render json: @condition, status: :accepted
    end
  end

  api :PUT, '/dialogues/:dialogue_id/variables/:variable_id/options/:id'
  description "update option of variable"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  param :value, String, desc: "wit value in Synonyms"
  param :display_count, :number
  def update
    if @option.update(option_params)
      render json: @option, status: :ok
    else
      render json: @option.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/conditions/:condition_id/options/:id/remove_from_condition'
  param :id, :number, required: true
  param :condition_id, :number, required: true
  def remove_from_condition
    unless @condition.arc.child.project.user_projects.where("user_id = ? and role = 0 or role = 1", current_user).first
      render plain: "You are not authorized", status: :unprocessable_entity and return
    end
    if @condition.parameter_id.nil?
      @condition.destroy
    else
      @option.condition.option_id = nil
      @option.condition.save!
    end
    render json: {body: 'Option was successfully destroyed.' }
  end

  api :DELETE, '/dialogues/:dialogue_id/variables/:variable_id/options/:id'
  description "delete option of variable"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  def destroy
    tmp = @option
    @option.destroy
    render json: {body: 'Option was successfully destroyed.', destroyed_option: tmp}
  end
  private

    def set_option
      @option = Option.find_by_id(params[:id])
      if @option.nil?
        render json: 'Option not exist.', status: 404
      end
    end

    def set_condition
      return if params[:condition_id].nil?
      @condition = Condition.find_by_id(params[:condition_id])
    end

    def option_params
      params.permit(:variable_id, :arc_id, :value, :condition_id, :display_count)
    end

    def is_variable_owner?
      if Variable.where(id: option_params[:variable_id], dialogue_id: params[:dialogue_id]).length == 0
        render body: "this dialogue doesn't have this variable!", status: :unprocessable_entity
      end
    end

    def is_option_owner?
      if Option.where(id: params[:id], variable_id: option_params[:variable_id]).length == 0
        render body: "this variable doesn't have this option!", status: :unprocessable_entity
      end
    end
end
