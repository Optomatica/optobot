require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'
  
resource "Chatbots" do

  after(:all) do
      User.destroy_all 
      Project.destroy_all
      UserProject.destroy_all
      Context.destroy_all
      Dialogue.destroy_all
      Arc.destroy_all
      Variable.destroy_all
      Parameter.destroy_all
      Condition.destroy_all
      Response.destroy_all
      ResponseContent.destroy_all
  end

  before (:all) do
      @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
      @new_auth_header = @user.create_new_auth_token()
      #@project = Project.create!()
      @project = Project.create!(name: "project_test" , nlp_engine: {en: "NZ3FCS4UXPXPG7VI7XE2YZI5DXOXIEOI"})
      @context = Context.create!(name: "first_context" , project_id: @project.id)
      @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin" , send_email:true)
      @dialogue = Dialogue.create!(project_id: @project.id , context_id: @context.id , name: "good_dialogue", tag: "test")
      #@dialogue.add_root_parent!()
      #@parent_dialogue = Dialogue.create!(project_id: @project.id, name: "parent_dialogue", tag: "parent_test")
      #@child_dialogue = Dialogue.create!(project_id: @project.id, name: "child_dialogue", tag: "child_test")
      @arc = Arc.create!( child_id: @dialogue.id)
      @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id ,entity: "Greeting", possible_values: ["hi","hello","hey"])
      @parameter = Parameter.create!(project_id: @project.id , value: "hi")
      #@condition = Condition.create!(arc_id: @arc.id, parameter_id: @parameter.id, variable_id: @variable.id)
      #@response = Response.create!( response_owner_id: @variable.id , response_owner_type: "Variable")
      @response = Response.create!( response_owner_id: @dialogue.id , response_owner_type: "Dialogue")
      @response_content = ResponseContent.create(response_id: @response.id, content: {"en" => "first-reply"})

      @initial_dialogue = Dialogue.create!(project_id: @project.id, context_id: @context.id , name: "start_node", tag: "start_node")
      @d_response = Response.create!(response_owner_id: @initial_dialogue.id, response_owner_type: "Dialogue", response_type: 'response')
      @r_content = ResponseContent.create(response_id: @d_response.id, content: {'en' => 'Hi, how can i help you?'})
  end

  before(:each) do
    header "access-token", @new_auth_header["access-token"]
    header "token-type", @new_auth_header["token-type"]
    header "client", @new_auth_header["client"]
    header "expiry", @new_auth_header["expiry"]
    header "uid", @new_auth_header["uid"]
    header "Content-Type", "application/json"
  end

  # get "/auth/validate_token" do
  #   example "auth" do
  #     do_request
  #   end
  # end

  # post "/projects/:id/linkFacebook" do
  #     parameter :id, :number, required: true
  #     parameter :connection_id, :number
  #     parameter :language, String, "ISO 639-1 code"
  #     let(:id){@project.id}
  #     let(:raw_post){{
  #         connection_id: @Connection.id,
  #         language: "en"
  #       }.to_json}
  #     example "linkFacebook" do
  #         do_request
  #     end
  # end

  # messages from facebook messenger 
  # post "/users/:user_id/webhook" do
  #      parameter :id, :number, required: true
  #      let(:id){@user.id}
  #     example "webhook" do
  #         do_request
  #     end
  # end
    
  post "/projects/:project_id/send_message_to_user" do
    parameter :project_id, :number, required: true
    parameter :debug_mode, :boolean, default: false
    parameter :text, String
    parameter :email, String #, desc: "the email of the user I want to send message to"
    parameter :language, String #, "ISO 639-1 code"
    let(:project_id){@project.id}
    let(:raw_post){{
      email: @user.email,
      text: "message sent to user",
      debug_mode: true,
      language: "en"
    }.to_json}

    example "reply_to_user" do
      do_request
    end
  end



  post "/projects/:project_id/chatbot" do
    parameter :project_id, :number, required: true
    parameter :debug_mode, :boolean, default: false
    parameter :text, String
    parameter :email, String, desc: "user sent this text"
    parameter :language, String, "ISO 639-1 code"
    parameter :user_id, :number
    let(:project_id){@project.id}      # can not find it , I don't know why ?????
    let(:raw_post){{
      debug_mode: true,
      text: "hi",
      email: @user.email,
      language: "en",
      project_id: @project.id
    }.to_json}

    example "chatting with user" do
      do_request
    end
  end

  get '/projects/:id/initial_node' do
    parameter :id, :number, required: true
    let(:id) { @project.id }
    example 'get initial node to start/initiate chat with user.
             an initial node is set by specifing its name as "initial_node"
             ex.. [N:start_node]type your response here' do
      do_request
    end
  end
end
