class ResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :can_access_or_edit_dialogue_relatives?
  before_action :set_response_params
  before_action :set_response, only: [:show_for_dialogue, :show_for_variable, :show_for_option_of_dialogue, :show_for_option_of_variable, :destroy_for_dialogue, :destroy_for_variable, :destroy_for_option_of_dialogue, :destroy_for_option_of_variable]
  before_action :is_variable_owner?, only: [:show_for_variable, :create_for_variable, :reorder_for_variable, :destroy_for_variable]
  before_action :is_response_owner?, only: [:show_for_dialogue, :show_for_variable, :destroy_for_dialogue, :destroy_for_variable, :show_for_option_of_dialogue, :show_for_option_of_variable, :destroy_for_option_of_dialogue, :destroy_for_option_of_variable]
  before_action :is_option_of_variable?, only: [:show_for_option_of_variable, :destroy_for_option_of_variable]

  api :GET, '/dialogues/:dialogue_id/responses/:id/show'
  param :id, :number, required: true
  param :dialogue_id, :number, allow_nil: false, required: true
  def show_for_dialogue
    show
  end

  api :GET, '/dialogues/:dialogue_id/variables/:variable_id/responses/:id/show'
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, allow_nil: false, required: true
  def show_for_variable
    show
  end

  api :GET, '/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/:id/show'
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, allow_nil: false, required: true
  param :option_id, :number, allow_nil: false, required: true
  def show_for_option_of_variable
    show
  end

  api :POST, '/dialogues/:dialogue_id/responses/create'
  description "add new response for the current dialogue"
  param :dialogue_id, :number, required: true, allow_nil: false
  def create_for_dialogue
    dialogue=Dialogue.find(@response_params[:response_owner_id])
    @response_params[:order] = dialogue.responses.count+1
    create
  end

  api :POST, '/dialogues/:dialogue_id/variables/:variable_id/responses/create'
  description "add new variable for the current dialogue"
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  def create_for_variable
    variable=Variable.find(@response_params[:response_owner_id])
    @response_params[:order] = variable.responses.count+1
    create
  end


  api :POST, '/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/create'
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  param :option_id, :number, required: true, allow_nil: false
  def create_for_option_of_variable
    create
  end

  api :PUT, '/dialogues/:dialogue_id/responses/reorder'
  description "update response of dialogue"
  param :dialogue_id, :number, required: true, allow_nil: false
  param :response_ids_new_order, Array, of: Integer, desc: "simple array of numbers (responses ids in the new order)"
  def reorder_for_dialogue
    reorder
  end

  api :PUT, '/dialogues/:dialogue_id/variables/:variable_id/responses/reorder'
  description "update response of variable"
  param :dialogue_id, :number, required: true, allow_nil: false
  param :variable_id, :number, required: true
  param :response_ids_new_order, Array, of: Integer, required: true, desc: "simple array of numbers (responses ids in the new order)"
  def reorder_for_variable
    reorder
  end

  api :DELETE, '/dialogues/:dialogue_id/responses/:id/destroy'
  description "delete response of dialogue"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true, allow_nil: false
  def destroy_for_dialogue
    destroy
  end

  api :DELETE, '/dialogues/:dialogue_id/variables/:variable_id/responses/:id/destroy'
  description "delete response of variable"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  def destroy_for_variable
    destroy
  end


  api :DELETE, '/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/:id/destroy'
  description "delete response of option of variable"
  param :id, :number, required: true
  param :dialogue_id, :number, required: true
  param :variable_id, :number, required: true, allow_nil: false
  param :option_id, :number, required: true, allow_nil: false
  def destroy_for_option_of_variable
    destroy
  end

  private
    def show
      render json: {
        response: @response,
        contents: @response.response_contents
      }
    end
    def create
      @response = Response.new(@response_params)
      if @response.save
        render json: @response, status: :created
      else
        render json: @response.errors, status: :unprocessable_entity
      end
    end

    def reorder
      if params[:response_owner_type] == "Option"
        response_owner = Option.find_by_id(@response_params[:response_owner_id])
      elsif params[:response_owner_type] == "Dialogue"
        response_owner = Dialogue.find_by_id(@response_params[:response_owner_id])
      else
        response_owner = Variable.find_by_id(@response_params[:response_owner_id])
      end
      if params[:response_ids_new_order].uniq.length != params[:response_ids_new_order].length or response_owner.responses.length != params[:response_ids_new_order].uniq.length
          render body: "please enter the same ids of these responses' owner and all of them once!", status: :not_acceptable and return
      end
      params[:response_ids_new_order].each do |id|
        if response_owner.responses.find_by_id(id) == nil
          render body: "please enter only the same ids of these responses' owner!", status: :not_acceptable and return
        end
      end
      new_order=1
      begin
        ActiveRecord::Base.transaction do
          puts "params", params.to_json
          params[:response_ids_new_order].to_a.each do |response_id|
            response = Response.find(response_id)
            if response.update(order: new_order)
              new_order += 1
            end
          end
          render json: response_owner.id, status: :ok
        end
      rescue ActiveRecord::ActiveRecordError
        ActiveRecord::Rollback
        render body: "can't update the order of some response", status: :bad_request
      end
    end

    def destroy
      tmp = @response
      @response.destroy
      responses = Response.where(response_owner_id: @response.response_owner_id, response_owner_type: @response.response_owner_type).order(:order)
      new_order=1
      responses.each do |response|
        response.order = new_order
        new_order += 1
      end
        render json: {body: 'Response was successfully destroyed.', destroyed_respond: tmp }
    end

    def set_response
      @response = Response.find_by_id(params[:id])
      if @response.nil?
        render json: 'Response not exist.', status: 404
      end
    end

    def set_response_params
      if params[:option_id]!=nil
        params[:response_owner_id] = params[:option_id]
        params[:response_owner_type] = "Option"
      elsif params[:variable_id]!=nil
        params[:response_owner_id] = params[:variable_id]
        params[:response_owner_type] = "Variable"
      else
        params[:response_owner_id] = params[:dialogue_id]
        params[:response_owner_type] = "Dialogue"
      end
      @response_params = params.permit(:response_owner_id, :response_owner_type)
    end

    def is_variable_owner?
      if Variable.where(id: @response_params[:response_owner_id].to_i, dialogue_id: params[:dialogue_id].to_i).length == 0
        render body: "this dialogue doesn't have this variable!", status: :unprocessable_entity
      end
    end

    def is_option_of_variable?
      if Option.where(id: @response_params[:response_owner_id].to_i, variable_id: params[:variable_id].to_i).length == 0
        render body: "this variable doesn't have this option!", status: :unprocessable_entity
      end
    end

    def is_response_owner?
      if @response.response_owner_id != @response_params[:response_owner_id].to_i or @response.response_owner_type != @response_params[:response_owner_type]
        render body: "this #{@response_params[:response_owner_type]} doesn't have this response!", status: :unprocessable_entity
      end
    end
end
