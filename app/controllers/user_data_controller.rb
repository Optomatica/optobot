class UserDataController < ApplicationController
    before_action :authenticate_user!
    before_action except: [] do
        is_project(["admin", "author", "moderator"])
    end
    before_action :set_user_project
    before_action :set_user_datum, only: [:update, :destroy]


    api :POST, '/projects/:project_id/user_data/list'
	description "get the meesages of the user and the bot by number limit or starting date"
	param :id, :number, required: true
	param :project_id, :number, required: true
    param :user_id, :number
    def list
        user = User.find(params[:user_id])
        render body: {name: user.name, image: user.image, user_data: @user_project.user_data}.to_json, status: :ok
	end

	api :POST, '/projects/:project_id/user_data/create'
	description "get the meesages of the user and the bot by number limit or starting date"
	param :project_id, :number, required: true
    param :user_id, :number
	param :variable_id, :number, required: true
    param :option_id, :number
    param :value, String
    def create
        if @user_project.project.variables.find_by_id(params[:variable_id]).nil?
            render "variable not exist", status: :bad_request and return
        end
        @user_datum = UserDatum.new(user_datum_params.merge({user_project_id: @user_project.id}))
        if @user_datum.save
            render json: @user_datum, status: :created
        else
            render json: @user_datum.errors, status: :unprocessable_entity
        end
	end

	api :POST, '/projects/:project_id/user_data/:id/update'
	description "get the meesages of the user and the bot by number limit or starting date"
	param :project_id, :number, required: true
    param :user_id, :number
    param :user_datum_id, :number, required: true
	param :variable_id, :number, required: true
    param :option_id, :number
    param :value, String
    def update
        if params[:variable_id] and @user_project.project.variables.find_by_id(params[:variable_id]).nil?
            render "variable not exist", status: :bad_request and return
        end
        if @user_datum.update(user_datum_params)
            render json: @user_datum, status: :ok
        else
            render json: @user_datum.errors, status: :unprocessable_entity
        end
    end

    api :DELETE, '/projects/:project_id/user_data/:id/destroy or /projects/:id'
    description "delete project"
    param :id, :number, required: true
    param :user_id, :number
    def destroy
        tmp = @user_datum
        @user_datum.destroy
        render json: {body: 'Project was successfully destroyed.', destroyed_parameter: tmp }
    end

    private
    def set_user_project
        @user_project = UserProject.where(project_id: params[:project_id], user_id: params[:user_id]).first
        if @user_project.nil?
            render json: 'You are not in this project.', status: 404
        end
    end

    def set_user_datum
        @user_datum = @user_project.user_data.where(id: params[:id]).first
        if @user_datum.nil?
            render json: 'Data not exist.', status: 404
        end
    end

    def is_project(valid_roles)
        user_project = UserProject.where(project_id: params[:project_id], user_id: current_user.id).first
        unless user_project and valid_roles.include?(user_project.role)
            render body: nil, status: :unauthorized and return
        end
    end

    def user_datum_params
        p params
        params.permit(:variable_id, :option_id, :value)
    end
end
