class DialoguesController < ApplicationController
  before_action :authenticate_user!
  before_action :is_admin_or_author?, only: [:create, :list]
  before_action :set_dialogue, only: [:show, :update, :destroy, :get_responses_of_dialogue, :add_root_parent]
  before_action :can_access_or_edit?, only: [:show, :get_dialogues_of_context, :update, :destroy]

  api :GET, '/dialogues/:id/show'
  description "show dialogue with its parameters, responses and variables"
  param :id, :number, required: true
  param :context_id, :number
  def show
    render json: {
      dialogue: @dialogue,
      responses: @dialogue.responses.map{|r|r.response_contents.length == 0 ? r.as_json : r.as_json.merge(
        r.response_contents.first.as_json.except("id"))},
      variables: @dialogue.variables,
      intent: @dialogue.intent&.value
    }
  end


  api :POST, '/dialogues/list'
  description "list dialogues with its parents for some context"
  param :project_id, :number, required: true
  param :context_id, :number
  def list
    sequences = Arc.joins("INNER JOIN dialogues ON arcs.child_id = dialogues.id").where("dialogues.project_id =? and dialogues.context_id =?", dialogue_params[:project_id], dialogue_params[:context_id]).select("arcs.*").order("arcs.child_id").to_a
    @dialogues = Dialogue.where(project_id: dialogue_params[:project_id], context_id: dialogue_params[:context_id])
    ret=[]
    @dialogues.each do |dialogue|
      tmp = get_dialogue_data(dialogue, sequences)
      ret.push(tmp)
    end
    render :json => ret
  end

  api :POST, '/dialogues/create or /dialogues'
  description "add new dialogue for some context and add its parent(s)"
  param :context_id, :number
  param :project_id, :number, required: true
  param :tag, String
  param :intent, String
  param :name, String, required: true, allow_nil: false
  param :parents_ids, Array, of: Integer, desc: "simple array of numbers (parents ids)"
  def create
    if dialogue_params[:name].nil?
      render body: "name is required", status: :bad_request and return
    end
    if Context.find_by_id(dialogue_params[:context_id]).nil?
      render body: "Invalid context", status: :bad_request and return
    end
    @dialogue = Dialogue.new(dialogue_params)
    if @dialogue.save
      Intent.create!(dialogue_id: @dialogue.id , value: params[:intent]) if params[:intent]
      add_parents
      dialogue = Dialogue.find(@dialogue.id)
      sequences = dialogue.parents_arcs.to_a
      tmp= get_dialogue_data(dialogue, sequences)
      render json: tmp, status: :created
    else
      render json: @dialogue.errors, status: :unprocessable_entity
    end
  end

  def add_root_parent
    begin
      Arc.add_relations([nil], [@dialogue.id])
      dialogue = Dialogue.find(@dialogue.id)
      sequences = dialogue.parents_arcs.to_a
      tmp= get_dialogue_data(dialogue, sequences)
      render json: tmp, status: :ok
    rescue  ActiveRecord::ActiveRecordError
      ActiveRecord::Rollback
      render json: @dialogue.errors, status: :unprocessable_entity
    end
  end

  api :PUT, '/dialogues/:id/update or /dialogues/:id'
  description "update dialogue context and add and remove parent(s)"
  param :id, :number, required: true
  param :context_id, :number
  param :tag, String
  param :intent, String
  param :name, String, allow_nil: false
  param :added_parents, Array, of: Integer, desc: "simple array of numbers (parents ids to add its relations)"
  param :removed_parents, Array, of: Integer, desc: "simple array of numbers (parents ids to remove its relations)"
  def update
    if !dialogue_params[:name].nil? and dialogue_params[:name].blank?
      render body: "name is blank while it doesn't accept null", status: :bad_request and return
    end
    begin
      ActiveRecord::Base.transaction do
        @dialogue.update_attributes(dialogue_params)
        if params[:intent]
          dialogues = @dialogue.project.dialogues.joins(:intent).select("dialogues.*").where("intents.value =?", params[:intent].downcase)
          intent = dialogues.first.intent unless dialogues.empty?
          intent = Intent.create!(dialogue_id: @dialogue.id , value: params[:intent]) unless intent
          @dialogue.update!(intent: intent)
        end
        if params[:added_parents] != nil and params[:added_parents].length != 0
          add_parents
        end
        if params[:removed_parents] != nil and params[:removed_parents].length != 0
          remove_parents
        end
      end
      dialogue = Dialogue.find(@dialogue.id)
      sequences = dialogue.parents_arcs.to_a
      tmp= get_dialogue_data(dialogue, sequences)
      render json: tmp, status: :ok
    rescue  ActiveRecord::ActiveRecordError
      ActiveRecord::Rollback
      render json: @dialogue.errors, status: :unprocessable_entity
    end
  end

  api :DELETE, '/dialogues/:id/destroy or /dialogues/:id'
  description "delete dialogue"
  param :id, :number, required: true
  def destroy
    tmp = @dialogue
    @dialogue.destroy
    render json: {body: 'Dialogue was successfully destroyed.', destroyed_parameter: tmp}
  end

  private
    def set_dialogue
      @dialogue = Dialogue.where(id: params[:id]).first
      if @dialogue.nil?
        render json: 'Dialogue not exist.', status: 404
      end
    end

    def dialogue_params
      params.permit(:name, :context_id, :project_id, :actions, :tag)
    end

    def set_project
      @project = Project.find(dialogue_params[:project_id])
    end


    def parents_has_same_context?
      params[:parents_ids].to_a.each do |parent_id|
        parent=Dialogue.find_by_id(parent_id)
        if parent.nil?
          return ActiveRecord::ActiveRecordError
        elsif parent.context_id!=dialogue_params[:context_id]
          render body: "one or more parents don't have the same context", status: :unprocessable_entity
        end
      end
    end

    def add_parents
      return Arc.add_relations(params[:parents_ids] ? params[:parents_ids] : params[:added_parents], [@dialogue.id])
    end

    def remove_parents
      return Arc.remove_relations(params[:removed_parents], [@dialogue.id])
    end

    def get_dialogue_data(dialogue, sequences)
      tmp={}
      tmp[:dialogue] = dialogue.as_json.merge({intent: dialogue.intent&.value})
      tmp[:arcs]={}
      i = sequences.length-1
      while i>=0 do
        if sequences[i].child_id==dialogue.id
          conditions = []
          sequences[i].conditions.each{|x| conditions.push({id: x.id, parameter: x.parameter, option: x.option.nil? ? nil : x.option.as_json.merge(
            x.option.response.response_contents.first.nil? ? {} : x.option.response.response_contents.first.as_json.except("id"))
            })}
          tmp[:arcs][sequences[i].id] = {parent_id: sequences[i].parent_id, conditions: conditions}
          sequences.delete_at(i)
        end
        i-=1
      end
      tmp
    end

    def can_access_or_edit?
      unless current_user.user_projects.where("project_id = ? and role = 0 or role = 1", @dialogue.project_id).first
        render body: "You are not authorized to do this action.", status: :bad_request
      end
    end
end
