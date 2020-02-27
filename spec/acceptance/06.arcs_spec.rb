require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'

resource "Arcs" do
  context 'arcs' do

  after(:all) do
      User.destroy_all
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
      Arc.destroy_all
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

  get "/arcs/:id" do
      parameter :id, "Arc's id", :number, required: true
      let(:id){@arc.id}
      example "show Arc" do
        do_request
      end
  end

  get "/arcs/:id/list_variables" do
      parameter :id, "Arc's id", :number, required: true
      let(:id){@arc.id}

      example "list_variables of Arc" do
        do_request
      end
  end


  post "/arcs/:arc_id/options/:id/add_to_condition" do
      parameter :arc_id, :number
      parameter :id, :number, required: true
      parameter :condition_id, :number, required: false
      let(:arc_id){@arc.id}
      let(:id){@option.id}
      let(:raw_post){{
          condition_id: @condition.id
      }.to_json}
      example "add condition" do
          do_request
      end
    end

  end
end
