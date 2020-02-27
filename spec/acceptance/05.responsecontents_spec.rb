require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'
  
resource "Response Contents " do

  after(:all) do
      User.destroy_all 
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
      Arc.destroy_all
      Option.destroy_all
      Variable.destroy_all
      # Response.destroy_all
      # ResponseContent.destroy_all

  end

  before (:all) do
      @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
      @new_auth_header = @user.create_new_auth_token()
      @project = Project.create!()
      @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "author")
      @dialogue = Dialogue.create!(project_id: @project.id, name: "good_dialogue", tag: "test")
      @parent_dialogue = Dialogue.create!(project_id: @project.id, name: "parent_dialogue", tag: "parent_test")
      @child_dialogue = Dialogue.create!(project_id: @project.id, name: "child_dialogue", tag: "child_test")
      @arc = Arc.create!(parent_id: @parent_dialogue.id, child_id: @child_dialogue.id)
      @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id)
      @option = Option.create!(variable_id: @variable.id)
      @condition = Condition.create!(arc_id: @arc.id, option_id: @option.id, variable_id: @variable.id)
      
      @response_for_dialogue = Response.create!(response_owner: @dialogue, order: 1)
      @response_for_variable = Response.create!(response_owner: @variable, order: 1)
      @response_contents_dia = ResponseContent.create!(response_id: @response_for_dialogue.id, content: {"en" => "english response"}, content_type:0)
      @response_contents_var = ResponseContent.create!(response_id: @response_for_variable.id, content: {"en" => "english response"}, content_type:0)

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


  post "/dialogues/:dialogue_id/responses/:response_id/response_contents/create" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    parameter :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    let(:dialogue_id){@dialogue.id}
    let(:response_id){@response_for_dialogue.id}
    let(:raw_post){{
        content: { "en" => "english response" },
        content_type: "text"
    }.to_json}
    example "add new response content for the current response of the dialogue " do
        do_request
    end
  end


  post "/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/create" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    parameter :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:response_id){@response_for_variable.id}
    let(:raw_post){{
        content: { "en" => "english response" },
        content_type: "text"
    }.to_json}
    example "add new response content for the current response of the variable" do
        do_request
    end
  end


  

  put "/dialogues/:dialogue_id/responses/:response_id/response_contents/:id/update" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    parameter :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    parameter :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    let(:dialogue_id){@dialogue.id}
    let(:response_id){@response_for_dialogue.id}
    let(:id){@response_contents_dia.id}
    let(:raw_post){{
        content: { "en" => "english response" },
        content_type: "text"
    }.to_json}
    example "update response content of the current response" do
        do_request
    end
  end

  put "/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/:id/update" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    parameter :content, Hash, required: true, allow_nil: false, desc: "the content of the response. the hash keys is the language of the content"
    parameter :content_type, String, allow_nil: false, desc: "text, image or video (default: text)"
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:response_id){@response_for_variable.id}
    let(:id){@response_contents_var.id}
    let(:raw_post){{
        content: { "en" => "english response" },
        content_type: "text"
    }.to_json}
    example "update response content of the current response" do
        do_request
    end
  end


  delete "/dialogues/:dialogue_id/responses/:response_id/response_contents/:id/destroy" do
    
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:response_id){@response_for_dialogue.id}
    let(:id){@response_contents_dia.id}
    
    example "delete response content of the current response" do
        do_request
    end
  end

  delete "/dialogues/:dialogue_id/variables/:variable_id/responses/:response_id/response_contents/:id/destroy" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :response_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:response_id){@response_for_variable.id}
    let(:id){@response_contents_var.id}      
    example "delete response content of the current response" do
        do_request
    end
  end


end
