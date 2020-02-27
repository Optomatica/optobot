require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'


resource "Users" do

  after(:all) do
      User.destroy_all 
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
      Option.destroy_all
      Variable.destroy_all
      Context.destroy_all
      UserDatum.destroy_all
  end

  before (:all) do
    @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
    @new_auth_header = @user.create_new_auth_token()
    @project = Project.create!()
    @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")
    @context = Context.create!(name: "my_context" , project_id: @project.id)
    @dialogue = Dialogue.create!(project_id: @project.id, name: "good_dialogue", tag: "test")
    @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id)
    @option = Option.create!(variable_id: @variable.id)
    @user_datum = UserDatum.create!(user_project_id: @user_project.id ,variable_id: @variable.id  , option_id: @option.id , value: "user's data")
    end
  
  before(:each) do
    header "access-token", @new_auth_header["access-token"]
    header "token-type", @new_auth_header["token-type"]
    header "client", @new_auth_header["client"]
    header "expiry", @new_auth_header["expiry"]
    header "uid", @new_auth_header["uid"]
    header "Content-Type", "application/json"
  end

  post "/auth" do
    parameter :email, :number, required: true
    parameter :password, :number, required: true
    parameter :password_confirmation, :number, required: true
    let(:raw_post){{
      email: "tester@example.com",
      password: "password",
      password_confirmation: "password"
    }.to_json}
    example "sign_up" do
      do_request
    end
  end

  get "/auth/validate_token" do
    example "auth" do
      do_request
    end
  end
    

  post "/projects/:project_id/user_data/list" do
    parameter :project_id, :number, required: true
    parameter :user_id, :number 
    let(:project_id){@project.id}
    let(:raw_post){{
      user_id: @user.id
    }.to_json}
    example "list user_data " do
        do_request
    end
  end
      



  post "/projects/:project_id/user_data/create" do
      parameter :project_id, :number, required: true
      parameter :user_id, :number
      parameter :variable_id, :number, required: true
      parameter :option_id, :number
      parameter :value, String , "user's data values"

      let(:project_id){@project.id}
      let(:raw_post){{
        user_id: @user.id,
        variable_id: @variable.id,
        option_id: @option.id,
        value: "user's data values"
      }.to_json}
      example "create user_data" do
          do_request
      end
  end


  put "/projects/:project_id/user_data/:id/update" do
      parameter :project_id, :number, required: true
      parameter :user_id, :number
      parameter :id, :number, required: true
      parameter :variable_id, :number, required: true
      parameter :option_id, :number
      parameter :value, String
      let(:project_id){@project.id}
      let(:id){@user_datum.id}
      let(:raw_post){{
        user_id: @user.id,
        variable_id: @variable.id,
        option_id: @option.id,
        value: "user's data new values"
      }.to_json}
      example "update user_data" do
        do_request
      end
    end
    


  delete "/projects/:project_id/user_data/:id/destroy" do 
    parameter :project_id, :number
    parameter :id, :number, required: true
    parameter :user_id, :number
    let(:project_id){@project.id}
    let(:id){@user_datum.id}

    let(:raw_post){{
      user_id: @user.id
    }.to_json}

    example "delete user_data" do
    do_request
    end
  end

end



