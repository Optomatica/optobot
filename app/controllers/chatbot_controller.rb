require 'mustache'
include ChatbotHelper

class ChatbotController < ApplicationController
  before_action :set_project, except: [:webhook]
  before_action :check_email_and_set_user, except: [:webhook, :send_message_to_user]
  before_action :can_chat_with_bot_and_set_user_project, except: [:webhook, :linkFacebook, :send_message_to_user]
  before_action :set_lang
  before_action :authenticate_user!, except: [:webhook]
  before_action :swich_to_production?, except: [:webhook]

  api :POST, '/linkFacebook'
  description ""
  param :connection_id, :number
  param :language, String, "ISO 639-1 code"
  def linkFacebook
    # For Facebook Account Linking
    @current_user = current_user if current_user

    p connection = Connection.find_by_id(params[:connection_id])
    if MessengerHelper.account_linking_callback(params[:redirect_uri], connection.tmp_params["authorization_code"]) # if succeeded
      p user_project = connection.user_project
      user_project.user_id = @current_user.id
      user_project.save!
    end
  end

  api :POST, 'users/webhook'
  def webhook
    # Facebook webhook endpoint
    if params['object'] == "page"
      requestes_responses = []
      p "ok"

      message = params['entry'].first['messaging'][0]['message']
      post_back = params['entry'].first['messaging'][0]["postback"]

      params[:text] = message['quick_reply']['payload'] if message && message['quick_reply']
      params[:text] = message['text'] if message && params[:text].nil?
      params[:text] = post_back['payload'] if post_back && params[:text].nil?


      p params[:text]
      bot_page_id = params['entry'].first['messaging'][0]["recipient"]["id"]
      @project = Project.where(facebook_page_id: bot_page_id).first
      render body: nil, status: :ok unless @project
      page_access_token = @project.facebook_page_access_token if @project
      user_psid = params['entry'].first['messaging'][0]["sender"]["id"]

      MessengerHelper.send_action(page_access_token, user_psid, "mark_seen")
      connection = Connection.where(connection_type: "facebook", connection_value: user_psid).first
      if connection.nil?
        @user_project = UserProject.create!(project_id: @project.id, role: "subscriber")
        MessengerHelper.account_link(page_access_token, user_psid)
        authorization_code = SecureRandom.alphanumeric(80)
        @user_project.connections.create!(connection_type: "facebook", connection_value: user_psid, tmp_params: {authorization_code: authorization_code})
      else
        @user_project = connection.user_project
        @current_user = connection.user_project.user
      end

      if params[:text]
        @project = @project.prod_project
        MessengerHelper.send_action(page_access_token, user_psid, "typing_on")
        params[:project_id] = @project.id
        puts params
        bot_will_say = chat_process(nil, @project, @user_project, params)
        MessengerHelper.send_action(page_access_token, user_psid, "typing_off")

        p "bot_will_say == " , bot_will_say

        persona_id = nil
        if(bot_will_say[:dialogue])
          dialogue = Dialogue.find(bot_will_say[:dialogue][:id])
          persona_id = dialogue.context.facebook_persona_id if dialogue && dialogue.context
        end

        responses = []
        responses += bot_will_say[:dialogue][:responses] if (bot_will_say[:dialogue] and bot_will_say[:dialogue][:responses])
        responses += bot_will_say[:variable][:responses] if bot_will_say[:variable] and bot_will_say[:variable][:responses]
        requestes_responses += MessengerHelper.send_responses(page_access_token, responses, user_psid, bot_will_say[:variable], @project, @user_project, persona_id)

        p requestes_responses
      end
      if requestes_responses.any? {|r| r.code != 200}
        requestes_responses.each{|r| p r.body}
        render json: bot_will_say, status: :ok
      else
        render json: bot_will_say, status: :ok
      end
    end
  end

  api :POST, '/reply_to_user'
  description "Send message to user by email"
  param :debug_mode, :boolean, default: false
  param :text, String
  param :project_id, :number
  param :email, String, desc: "the email of the user I want to send message to"
  param :language, String, "ISO 639-1 code"
  def send_message_to_user
    user_project = @project.user_projects.joins(:user).where("users.email = ?", params[:email]).first
    # todo send with user_project_id not email
    if user_project
      user_message = ChatbotMessage.create!(user_project_id: user_project.id, message: params[:text], is_user_message: false)
      page_access_token = @project.facebook_page_access_token
      if page_access_token
        user_project.connections.each{|c|
          MessengerHelper.send_responses(page_access_token, {text: params[:text]}, c.connection_value, bot_will_say[:variable], @project, user_project)
        }
      end
      render json: "Message sent!".to_json , status: 200
    else
      render json: nil, status: :bad_request
    end
  end

  api :POST, '/chatbot'
  description ""
  param :debug_mode, :boolean, default: false
  param :text, String
  param :project_id, :number
  param :email, String, desc: "the email of the user that signed-in by the account admin"
  param :language, String, "ISO 639-1 code"
  param :formResponse, Array, of: Hash
  def chat
    if params[:text] == "end" and params[:debug_mode]
      @user_chatbot_session = @user_project.user_chatbot_session
      @user_chatbot_session.destroy! if @user_chatbot_session
      @user_project.user_data.destroy_all
      p " session destroyed! chat ends, bye "
      render json: {body: "session destroyed! chat ends, bye"}
    else
      if params[:formResponse].present?
        render json: handle_form_response(params, @user_project.user_chatbot_session)
      else
        render json: chat_process(current_user, @project, @user_project, params)
      end
    end
  end

  private
  def chatbot_params
    return params.permit(:project_id, :text, :email, :language, :debug_mode, :speech, "Content-type", :encoding, :bits, :rate, :endian, :audio)
  end

  def set_project
    p  " in set_project given  params[:id] == #{params[:id]}"
    @project = Project.find_by_id(params[:id])
    if @project.nil?
      render json: 'Project not found.', status: 404
    end
  end

  def swich_to_production?
    @project = @project.prod_project if !params[:debug_mode]
  end

  def check_email_and_set_user
    email = params[:email]
    return if email.nil? || !is_admin?

    current_user = User.find_by(email: email)
  end

  def can_chat_with_bot_and_set_user_project
    unless current_user || @project.is_private
      anon_user = User.create_anonymous_user
      user_project = UserProject.create!(project:@project, role: :subscriber)
      anon_user.user_projects << user_project
      sign_in(anon_user)
    end
    @user_project = @project.get_user_project(current_user)
    render body: nil, status: :unauthorized and return unless @user_project
  end

end
