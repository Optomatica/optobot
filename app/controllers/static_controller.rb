class StaticController < ApplicationController
  before_action :skip_pundit_auth
  skip_before_action :authenticate_user!

  def static_page
    render :file => "#{Rails.root}/public/index.html", :layout =>  false and return
  end
end
