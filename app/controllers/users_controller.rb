class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:vwebhook]
  before_action :user_signed_in?, only: [:show]
  before_action :same_user?, only: [:show]

  def show
    render json: current_user.to_json
  end

  def vwebhook
    # Parse the query params
    mode = params['hub.mode']
    token = params['hub.verify_token']
    challenge = params['hub.challenge']
    project = Project.where(facebook_page_access_token: token).first

    is_mode_subscribe_and_proj = (mode === 'subscribe' && project)
    # Checks if a token is in the query string of the request
    # And checks the mode and token sent is correct
    if token && is_mode_subscribe_and_proj
      # Responds with the challenge token from the request
      p 'WEBHOOK_VERIFIED'
      render status: 200, json: challenge
    elsif !is_mode_subscribe_and_proj
      # verify tokens do not match
      render status: 403
    end
  end
end
