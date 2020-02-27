require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'

resource "Options" do
  context 'options' do

  after(:all) do
      User.destroy_all
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
      Arc.destroy_all
      Option.destroy_all
      Variable.destroy_all

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
      @variable = Variable.create!(name: "variable_name", dialogue: @dialogue , project: @project)
      @option = Option.create!(variable_id: @variable.id)
      @condition = Condition.create!(arc_id: @arc.id, option_id: @option.id, variable_id: @variable.id)
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


  get "/dialogues/:dialogue_id/variables/:variable_id/options/list" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :variable_id, :number, required: true, allow_nil: false
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    example "list all options of current dialogue and its variables" do
        do_request
    end
    end



  post "/dialogues/:dialogue_id/variables/:variable_id/options/create" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :value, String, required: true, desc: "wit value in Synonyms"
    parameter :display_count, :number
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:raw_post){{
        value: "option's value",
        display_count: 3
    }.to_json}
    example "add new variable for the current dialogue" do
        do_request
    end
  end

  put "/dialogues/:dialogue_id/variables/:variable_id/options/:id" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    parameter :value, String, desc: "wit value in Synonyms"
    parameter :display_count, :number

    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:id){@option.id}
    let(:raw_post){{
        value: "option's value",
        display_count: 3
    }.to_json}
    example "update option of variable" do
        do_request
    end
  end



  delete "/conditions/:condition_id/options/:id/remove_from_condition" do
    parameter :condition_id, :number, required: true
    parameter :id, :number, required: true

    let(:condition_id){@condition.id}
    let(:id){@option.id}

    example "remove option of variable" do
        do_request
    end
  end


  delete "/dialogues/:dialogue_id/variables/:variable_id/options/:id" do
    parameter :id, :number, required: true
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false

    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:id){@option.id}

    example "delete option of variable" do
        do_request
    end
  end

  end
end
