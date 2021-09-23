class ResponseContentsController < ApplicationController
    before_action :authenticate_user!
    before_action :can_access_or_edit_dialogue_relatives?
    before_action :set_response_content, only: [:update_for_dialogue, :update_for_variable, :destroy_for_dialogue, :destroy_for_variable]
    before_action :set_lang
    before_action :is_variable_owner?, only: [:create_for_variable, :update_for_variable, :destroy_for_variable]
    before_action :is_response_owner?
    before_action :is_response_content_owner?, only: [:show_for_dialogue, :show_for_variable, :update_for_dialogue, :update_for_variable, :destroy_for_dialogue, :destroy_for_variable]


    api :POST, '/dialogues/:dialogue_id/responses/:response_id/response_contents/create'
    description "add new response content for the current response"
    param :response_id, :number, required: true, allow_nil: false
    param :dialogue_id, :number, required: true, allow_nil: false
    param :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    param :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    def create_for_dialogue
      create
    end

    api :POST, '/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/create'
    description "add new response content for the current response"
    param :response_id, :number, required: true, allow_nil: false
    param :variable_id, :number, required: true, allow_nil: false
    param :dialogue_id, :number, required: true, allow_nil: false
    param :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    param :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    def create_for_variable
      create
    end

    api :PUT, '/dialogues/:dialogue_id/responses/:response_id/response_contents/:id/update'
    description "update response content of the current response"
    param :id, :number, required: true
    param :dialogue_id, :number, required: true, allow_nil: false
    param :response_id, :number, required: true, allow_nil: false
    param :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    param :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    def update_for_dialogue
        update
    end
    api :PUT, '/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/:id/update'
    description "update response content of the current response"
    param :id, :number, required: true
    param :dialogue_id, :number, required: true, allow_nil: false
    param :variable_id, :number, required: true, allow_nil: false
    param :response_id, :number, required: true, allow_nil: false
    param :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    param :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    def update_for_variable
        update
    end

    api :DELETE, '/dialogues/:dialogue_id/responses/:response_id/response_contents/:id/destroy'
    description "delete response content of the current response"
    param :id, :number, required: true
    param :dialogue_id, :number, required: true, allow_nil: false
    param :response_id, :number, required: true, allow_nil: false
    def destroy_for_dialogue
      destroy
    end
    api :DELETE, '/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/:id/destroy'
    description "delete response content of the current response"
    param :id, :number, required: true
    param :dialogue_id, :number, required: true, allow_nil: false
    param :variable_id, :number, required: true, allow_nil: false
    param :response_id, :number, required: true, allow_nil: false
    def destroy_for_variable
      destroy
    end

    private
      def create
        if params[:content].nil? or params[:content].keys.all?{|k| params[:content][k].nil? or params[:content][k].blank?}
          render body: "content is required", status: :bad_request and return
        end
        @response_content = ResponseContent.new(response_content_params)
        if @response_content.save
          render json: @response_content, status: :created
        else
          render json: @response_content.errors, status: :unprocessable_entity
        end
      end

      def update
        if params[:content].nil? or params[:content].keys.all?{|k| params[:content][k].nil? or params[:content][k].blank?}
          render body: "content doesn't accept null but given blank!", status: :bad_request and return
        end
        if @response_content.update_attributes(response_content_params)
          render json: @response_content, status: :ok
        else
          render json: @response_content.errors, status: :unprocessable_entity
        end
      end

      def destroy
        tmp = @response_content
        @response_content.destroy
        render json: {body: 'Response was successfully destroyed.', destroyed_respond: tmp }
      end

      def set_response_content
        @response_content = ResponseContent.find_by_id(params[:id])
        if @response_content.nil?
          render json: 'ResponseContent not exist.', status: 404
        end
      end

      def response_content_params
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
        tmp = params.permit(:response_id, :content_type, :content)
        return tmp
      end

      def is_variable_owner?
        if Variable.where(id: params[:variable_id], dialogue_id: params[:dialogue_id]).length == 0
          render body: "this dialogue doesn't have this variable!", status: :unprocessable_entity
        end
      end

      def is_response_owner?
        if Response.where(id: response_content_params[:response_id], response_owner_id: params[:response_owner_id], response_owner_type: params[:response_owner_type]).length == 0
          render body: "this #{params[:response_owner_type]} doesn't have this response!", status: :unprocessable_entity
        end
      end

      def is_response_content_owner?
        if ResponseContent.where(id: params[:id], response_id: response_content_params[:response_id]).length == 0
          render body: "this response doesn't have this content!", status: :unprocessable_entity
        end
      end
end
