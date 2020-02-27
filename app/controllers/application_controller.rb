class ApplicationController < ActionController::Base
  include MainHelper
  include DeviseTokenAuth::Concerns::SetUserByToken
  protect_from_forgery with: :null_session

end
