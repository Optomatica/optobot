require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'
  
resource "Parameters" do

  after(:all) do
      User.destroy_all 
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
      Arc.destroy_all
      Option.destroy_all
      Variable.destroy_all
      Condition.destroy_all
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
      @parameter = Parameter.create!(project_id: @project.id ,value: "value" )
      @condition = Condition.create!(arc_id: @arc.id, option_id: @option.id, variable_id: @variable.id , parameter_id: @parameter.id)
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

  post "/arcs/:arc_id/parameters/create" do	
    parameter :arc_id, :number, required: true, allow_nil: false
    parameter :condition_id, :number, required: false, allow_nil: false
    parameter :project_id, :number, required: false, allow_nil: false
    parameter :variable_id, :number, required: false, allow_nil: false, desc: "required = true if no condition id"
    parameter :value, String, desc: "required if and only if params(min and max) are not exist"
    parameter :min, :number, desc: "required with param(max) if and only if param(value) is not exist"
    parameter :max, :number, desc: "required with param(min) if and only if param(value) is not exist"
    let(:arc_id){@arc.id}
    let(:raw_post){{
      project_id: @project.id,
      condition_id: @condition.id,
      variable_id: @variable.id,
      value: "value",
      min: '',
      max: ''
    }.to_json}
    example "add new parameters for the current dialogue" do
        do_request
    end
  end

  put "/arcs/:arc_id/parameters/:id/update" do	
    parameter :arc_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    parameter :project_id, :number, required: false, allow_nil: false
    parameter :value, String, desc: "don't add if params(min and max) are exist"
    parameter :min, :number, desc: "don't add if param(value) is exist"
    parameter :max, :number, desc: "don't add if param(value) is exist"
    let(:arc_id){@arc.id}
    let(:id){@parameter.id}
    let(:raw_post){{
      project_id: @project.id,
      value: "value updated",
      min: '',
      max: ''
    }.to_json}
    example "update parameter" do
        do_request
    end
  end


  delete "/arcs/:arc_id/parameters/:id/destroy" do	
    parameter :arc_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    let(:arc_id){@arc.id}
    let(:id){@parameter.id}
    example "delete parameter by id" do
        do_request
    end
  end

end
