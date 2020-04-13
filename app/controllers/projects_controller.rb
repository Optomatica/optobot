class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :same_user?, except: [:get_chat_messages, :get_chat_problems, :export_dialogues_data, :import_dialogues_data, :update_session, :release ,:train_wit, :import_context_dialogues_data]
  before_action :set_project, except: [:create, :list ]
  before_action only: [:update, :destroy, :add_users_to_project, :get_chat_problems,
                      :remove_users_from_project, :get_facebook_access_token] do
		is_project(["admin"])
	end
	before_action only: [:remove_problem, :update_session] do
		is_project(["admin", "author", "moderator"])
	end
  before_action :is_valid_role, only: [:add_users_to_project]
  before_action :check_email_and_set_user, only: [:get_chat_messages]
	before_action :swich_to_production?, only: [:get_chat_problems, :remove_problem, :get_chat_messages]

	InitialDataFile = "initial_data.json"

  api :POST, '/users/user_id/projects/create'
  description "Create new project"
  param :user_id, :number, required: true
  param :name, String, required: true
  param :nlp_engine, Hash
  param :external_backend, Hash
  param :is_private, :boolean
  param :fallback_setting, Hash
  param :facebook_page_access_token, String
  def create
		begin
      ActiveRecord::Base.transaction do
        cur_project_params = project_params
        cur_project_params.require(:name)
        if project_params[:nlp_engine].nil? || project_params[:nlp_engine].empty? || project_params[:nlp_engine]["en"].nil? || project_params[:nlp_engine]["en"].empty?
          response = current_user.create_wit_app( ENV['WIT_SERVER_TOKEN'] , current_user.email.split('@')[0] + "_" + project_params[:name] )
          p response
          response = JSON.parse(response.body)
          cur_project_params[:nlp_engine] = project_params[:nlp_engine].merge({en: response['access_token'] || ENV['WIT_SERVER_TOKEN']})
        end
        project = Project.create!(cur_project_params)
				user_project = current_user.user_projects.build(project:project)
				user_project.role = :admin
				user_project.save!

				prod_project = Project.create!(cur_project_params)
        project.prod_project = prod_project
        project.save!

				@project = project
      end
    rescue => e
      p e.message
      p e.backtrace
			ActiveRecord::Rollback
			render plain: e.message, status: :unprocessable_entity and return
    end
    render json: @project, status: :created
  end

  api :PUT, '/users/user_id/projects/:id/update'
  description "update project"
  param :user_id, :number, required: true
  param :id, :number, required: true
  param :name, String
  param :nlp_engine, Hash
  param :external_backend, Hash
  param :is_private, :boolean
  param :fallback_setting, Hash
  param :facebook_page_access_token, String
	def update
    ActiveRecord::Base.transaction do
      update_params = project_params.except(:facebook_page_access_token, :facebook_page_id)
			if @project.update_attributes(update_params) && @project.prod_project.update_attributes(update_params)
				render json: @project, status: :ok
			else
				ActiveRecord::Rollback
				render json: @project.errors, status: :unprocessable_entity
			end
		end
  end

  api :DELETE, '/users/user_id/projects/:id/destroy'
  description "destroy project"
  param :user_id, :number, required: true
  param :id, :number, required: true
  def destroy
    @project.destroy
    render body: nil, status: :ok
  end


  api :GET, '/users/user_id/projects/:id/show'
  description "show context"
  param :id, :number, required: true
  def show
    render :json => @project
  end

  api :GET, '/users/user_id/projects/list'
  description "list all user's projects as (Admin/author/subscriber)"
  def list
		user_projects = current_user.projects.where(prod_project_id: nil).select("projects.id, projects.name, projects.is_private, user_projects.role, projects.created_at")
		public_projects = Project.where(is_private: false, prod_project_id: nil).select(:id, :name, :is_private, :created_at)
    render :json => {user_projects: user_projects, public_projects: public_projects-user_projects}
	end

	api :PUT, '/projects/:id/update_session'
  param :id, :number, required: true
  param :user_id, :number, required: true
	param :user_chatbot_session_id, :number, required: true
	param :context_id, :number
	param :dialogue_id, :number
	param :variable_id, :number
	param :quick_response_id, :number
	param :fallback_counter, :number
	param :prev_session_id, :number
	param :next_session_id, :number
	def update_session
		if (user = User.find_by_id(params[:user_id])).nil?
			render json: nil, status: :bad_request and return
		end
		if (user_project = user.user_projects.where(project_id: @project.id).first).nil?
			render json: nil, status: :bad_request and return
		end
		 user_chatbot_session = UserChatbotSession.find_by_id(params[:user_chatbot_session_id])
		if user_chatbot_session.nil?
			render plain: 'you have no session to update!', status: :ok and return
		end
		user_chatbot_session.context_id = params[:context_id] if params[:context_id]
		user_chatbot_session.dialogue_id = params[:dialogue_id] if params[:dialogue_id]
		user_chatbot_session.variable_id = params[:variable_id] if params[:variable_id]
		user_chatbot_session.quick_response_id = params[:quick_response_id] if params[:quick_response_id]
		user_chatbot_session.fallback_counter = params[:fallback_counter] if params[:fallback_counter]
		user_chatbot_session.prev_session_id = params[:prev_session_id] if params[:prev_session_id]
		user_chatbot_session.next_session_id = params[:next_session_id] if params[:next_session_id]
		user_chatbot_session.save!
		render json: user_chatbot_session, status: :ok
	end

	api :DELETE, '/users/user_id/projects/:id/remove_problem'
  description "destroy project"
  param :user_id, :number, required: true
  param :id, :number, required: true
	param :problem_id, :number, required: true
	param :debug_mode, :boolean, default: false
	def remove_problem
		if params[:problem_id].nil?
			render json: nil, status: :bad_request and return
		end
		problem = @project.problems.find_by_id(params[:problem_id])
		problem.destroy
    render body: nil, status: :ok
	end

  api :POST, '/users/:user_id/projects/:id/add_users_to_project'
  description "add users to project"
  param :user_id, :number, required: true
  param :id, :number, required: true
  param :role, String, "auther or subscriber"
  param :user_ids, Array
	param :user_emails, Array
  param :send_emails, :boolean
  def add_users_to_project
		users = []
		begin
			ActiveRecord::Base.transaction do
				users += User.get_or_create_users(params[:user_emails])
				users.each do |user|
					UserProject.create!(project_id: @project.id, user_id: user.id, role: params[:role])
					UserMailer.invitation_to_chatbot({email: user.email, role: params[:role]}, current_user, Rails.root+"/projects/#{params[:id]}/show").deliver! if params[:send_emails] == true
				end
			end
	  render plain: "users added successfully #{users}", status: :ok and return
		rescue => e
			ActiveRecord::Rollback
			render body: e.message, status: :bad_request and return
		end

    render body: nil, status: :ok
	end

  api :POST, '/users/:user_id/projects/:id/remove_users_from_project'
  param :user_id, :number, required: true
  param :id, :number, required: true
  param :emails, Array, of: String
  def remove_users_from_project
    user_emails = params[:emails]
    if user_emails.include?(current_user.email) # check that he is not the project admin
      render body: "Don't remove yourself!
                    You are the only one who can remove the project!",
             status: :bad_request and return
    end

    users_projects = []
    user_emails.each do |email|
      user = User.find_by(email: email)
      unless @project.has_user(user)
        render body: "one or more email is not exist", status: :bad_request and return
      end

      users_projects << user.user_projects.where(project: @project)
    end

    users_projects.each(&:destroy_all)
    render json: 'Done'.to_json , status: :ok and return if users_projects.any?
  end

  api :GET, '/users/:user_id/projects/:id/list_account_users'
	param :id, :number, required: true
  def list_project_users
    users = @project.user_projects.map do |up|
      up.user.serializable_hash.merge('role' => up.role)
    end

    render json: users
  end

	api :GET, '/projects/:id/get_chat_problems','Get project\'s problems'
	description "get the problems of the project ordered by dialogue_id"
	param :debug_mode, :boolean, default: true
	def get_chat_problems
		problems = {}
		tmp_problems = @project.problems.joins(:chatbot_message).select("problems.*, chatbot_messages.dialogue_id").order("chatbot_messages.dialogue_id")
		tmp_problems.each do |problem|
			problems[problem.dialogue_id] = problem
		end
		render json: problems.to_json, status: :ok
	end

  api :POST, '/projects/:id/get_chat_messages','Get user\'s chat'
  description "get the meesages of the user and the bot by number limit or starting date"
  param :id, :number, required: true
  param :email, String, required: true, desc: "the email of the user that signed-in by the account admin"
  param :limiting_number, :number
  param :starting_date, Date
  def get_chat_messages
    user_project = @project.get_user_project(current_user)
    render body: nil, status: :bad_request and return if user_project.nil?

    limiting_number = params[:limiting_number]
    starting_date = params[:starting_date] ? Time.zone.at(params[:starting_date].to_i) : nil

    chat_messages = user_project.chatbot_messages
    chat_messages = chat_messages.limit(limiting_number) if limiting_number

    chat_messages = chat_messages.where('created_at > ?', starting_date) if starting_date

    render json: chat_messages, status: :ok
  end

	api :GET, '/users/:id/export_dialogues_data'
	def export_dialogues_data
		p @project
		data = {
			contexts: @project.export_contexts,
			dialogues_and_arcs: @project.export_dialogues
		}.to_json
		send_data data, filename: "project name.json", type: "application/json"
	end

	api :POST, '/users/:id/import_dialogues_data'
	param :file, File, required: true
	def import_dialogues_data
		if params["file"].nil?
			render plain: "Parameter file can't be empty!", status: :bad_request and return
		end
		if params[:file].content_type != "application/json"
			render plain: "Sorry, currently we only support json format files", status: :bad_request and return
		end

		file = params[:file].read
		data = JSON.parse(file,:symbolize_names => true)
		begin
			ActiveRecord::Base.transaction do
				@project.import_contexts(data[:contexts])
				@project.import_dialogues(data[:contexts], data[:dialogues_and_arcs])
			end
		rescue => e
			ActiveRecord::Rollback
			render plain: e.message, status: :bad_request
		end
	end

	api :POST, '/projects/:id/train_wit'
	param :file, File, required: true
	param :lang , String, required: true
	def train_wit
		file = params[:file].read
		train = @project.training_wit(file, params[:lang] || "en")
		render json: train, status: :ok

	end


	skip_before_action :verify_authenticity_token
	api :POST, '/projects/:id/import_dialogues_data'
	param :file, File, required: true
	param :context_id, Integer
  	def import_context_dialogues_data
		file = params[:file].read
		begin
			dialogues = @project.import_context_dialogues_data(file ,params[:context_id], params[:lang] || "en")
		rescue  => e
			render json: {error: e}, status: :not_acceptable
		else
			render json: dialogues, status: :ok
		end
	end

	api :GET, '/projects/:id/release','release project to production'
	description ""
	param :id, :number, required: true

	def release
		p @project
		# export
		data = {
			contexts: @project.export_contexts,
			dialogues_and_arcs: @project.export_dialogues
		}.to_json

		data = JSON.parse(data,:symbolize_names => true)

		if UserChatbotSession.all.where(context_id: @project.context_ids)
      @project.tmp_project.id = @project.prod_project.id
      begin
        ActiveRecord::Base.transaction do
          prod_project = Project.create!(nlp_engine: @project.nlp_engine, name: @project.name,
            external_backend: @project.external_backend, is_private: @project.is_private,
            fallback_setting: @project.fallback_setting, facebook_page_id: @project.facebook_page_id,
            version: @project.version)
          prod_project.import_contexts(data[:contexts])
          prod_project.import_dialogues(data[:contexts], data[:dialogues_and_arcs])
          @project.version += 1
          @project.prod_project_id = prod_project.id
          @project.save!
        end
      rescue => e
        ActiveRecord::Rollback
			  return render plain: e.message, status: :bad_request
      end
    else
      begin
			  ActiveRecord::Base.transaction do
          @project.user_projects.each{|up| up.user_chatbot_session&.destroy! } # for now delete all session
          prod_project = @project.prod_project
          #Delete all
          prod_project.dialogues.destroy_all
          prod_project.contexts.destroy_all

          #import
          prod_project.import_contexts(data[:contexts])
          prod_project.import_dialogues(data[:contexts], data[:dialogues_and_arcs])

          prod_project.update!(version: @project.version)
          @project.version += 1
          @project.save!
        end
      rescue => e
			  ActiveRecord::Rollback
			  return render plain: e.message, status: :bad_request
      end
    end
    render plain: "Congratulations", status: :ok
  end

  def set_facebook_access_token
    fb_page_id = params[:facebook_page_id]
    fb_user_id = params[:facebook_user_id]
    access_token = params[:facebook_page_access_token]
    render body: nil, status: :unprocessable_entity unless fb_page_id && fb_user_id && access_token

    begin
      ## get the user access token
      user_access_token_url = 'https://graph.facebook.com/v6.0/oauth/access_token'
      params = { grant_type: 'fb_exchange_token',client_id: ENV['FACEBOOK_APP_ID'],
                 client_secret: ENV['FACEBOOK_APP_SECRET'], fb_exchange_token: access_token }

      r = RestClient.get(user_access_token_url, {params: params, accept: :json})
      render json: {'error': 'Facebook Authentication Error'}, status: :unauthorized and return unless r.code == 200

      long_lived_token = JSON.parse(r.body)['access_token']

      ## get long lived page access token
      page_access_token_url = "https://graph.facebook.com/v6.0/#{fb_user_id}/accounts"
      params = {'access_token': long_lived_token}

      r = RestClient.get(page_access_token_url, {params: params, accept: :json})
      render json: {'error': 'Access Token Error'}, status: :unauthorized and return unless r.code == 200

      res_data = JSON.parse(r.body)['data']
      fb_page = res_data.select{|i| i['id'] == fb_page_id}.first
      fb_page_access_token = fb_page['access_token']

      @project.update!(facebook_page_access_token: fb_page_access_token,
                       facebook_page_id: fb_page_id)
      @project.connect_facebook_page

      fb_page_name = fb_page['name']
      render json: {'page_name': fb_page_name}, status: :ok
    rescue => e
      p e&.message
      p e&.response&.body

      render body: e&.message || e&.response&.body, status: :unprocessable_entity
    end
  end

  def enable_get_started
    get_started_node = @project.dialogues.where(name: 'get_started')
    if get_started_node.empty?
      render json: 'get started node not found in project', status: :unprocessable_entity
    else
      response = get_started_node[0].responses[0].response_contents[0].content['en']
      # MessengerHelper.get_started(@project.facebook_page_access_token, response)
      render body: nil, status: :ok
    end
  end

	private
    def set_project
      @project = current_user.projects.find_by_id(params[:id])
      if @project.nil?
				render json: 'Project not found.', status: 404
      end
		end

		def swich_to_production?
			@project = @project.prod_project if params[:debug_mode] == false or params[:debug_mode].nil?
		end

    def project_params
      params.permit(:name, :external_backend, :is_private, :facebook_page_access_token, :facebook_page_id, :facebook_user_id, :fallback_setting => {}, :nlp_engine => {})
    end

		def is_project(valid_roles)
			user_project = UserProject.where(project_id: @project.id, user_id: current_user.id).first
      unless valid_roles.include?(user_project.role)
        render body: "nil", status: :unauthorized and return
      end
    end

    def is_valid_role
      unless params[:role] == "author" or params[:role] == "subscriber" or params[:role] == "admin"
        render body: nil, status: :bad_request and return
      end
    end

    def check_email_and_set_user
      email = params[:email]
      return if email.nil? || !is_project(["admin"])

      user = User.find_by(email: params[:email])
      if user.nil? || !@project.has_user(user)
        render body: "this is not one of your users! you can add this user using '/users/:id/add_user_to_account'", status: :not_found
      else
        current_user = user
      end
    end

end
