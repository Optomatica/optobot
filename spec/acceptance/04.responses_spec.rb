require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'

resource "Response" do

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
      @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id)
      @option = Option.create!(variable_id: @variable.id)
      @condition = Condition.create!(arc_id: @arc.id, option_id: @option.id, variable_id: @variable.id)

      @response_for_dialogue = Response.create!(response_owner: @dialogue, order: 1)
      @response_for_variable = Response.create!(response_owner: @variable, order: 1)

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


  get "/dialogues/:dialogue_id/responses/:id/show" do
    parameter :dialogue_id, :number, allow_nil: false, required: true
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:id){@response_for_dialogue.id}
    example "show responses of the dialogue" do
        do_request
    end
  end


  get "/dialogues/:dialogue_id/variables/:variable_id/responses/:id/show" do
    parameter :dialogue_id, :number, allow_nil: false, required: true
    parameter :variable_id, :number, allow_nil: false, required: true
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:id){@response_for_variable.id}
    example "show responses for variable of the dialogue" do
        do_request
    end
  end


  get "/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/:id/show" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, allow_nil: false, required: true
    parameter :option_id, :number, allow_nil: false, required: true
    parameter :id, :number, required: true

    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:option_id){@option.id}
    let(:id){@response_for_variable.id}
    example "show responses for_option of variable of the dialogue" do
        do_request
    end
  end


  post "/dialogues/:dialogue_id/responses/create" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    let(:dialogue_id){@dialogue.id}
    example "add new response for the current dialogue" do
        do_request
    end
  end

  post "/dialogues/:dialogue_id/variables/:variable_id/responses/create" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    example "add new response for variable of the current dialogue" do
        do_request
    end
  end

  post "/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/create" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :option_id, :number, required: true, allow_nil: false
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:option_id){@option.id}
    example "add new response for option of variable for the current dialogue" do
        do_request
    end
  end



  put "/dialogues/:dialogue_id/responses/reorder" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :response_ids_new_order, Array, of: Integer, desc: "simple array of numbers (responses ids in the new order)"
    let(:dialogue_id){@dialogue.id}
    let(:raw_post){{
      response_ids_new_order: [@response_for_dialogue.id , @response_for_variable.id]
    }.to_json}
    example "update response of dialogue" do
        do_request
    end
  end


  put "/dialogues/:dialogue_id/variables/:variable_id/responses/reorder" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :variable_id, :number, required: true
    parameter :response_ids_new_order, Array, of: Integer, required: true, desc: "simple array of numbers (responses ids in the new order)"
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:raw_post){{
      response_ids_new_order: [@response_for_dialogue.id , @response_for_variable.id]
    }.to_json}
    example "update response of variable" do
        do_request
    end
  end


  delete "/dialogues/:dialogue_id/responses/:id/destroy" do
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:id){@response_for_dialogue.id}
    example "delete response of dialogue" do
        do_request
    end
  end


  delete "/dialogues/:dialogue_id/variables/:variable_id/responses/:id/destroy" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true

    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:id){@response_for_variable.id}
    example "delete response of variable" do
        do_request
    end
  end

  delete "/dialogues/:dialogue_id/variables/:variable_id/options/:option_id/responses/:id/destroy" do
    parameter :dialogue_id, :number, required: true
    parameter :variable_id, :number, required: true, allow_nil: false
    parameter :option_id, :number, required: true, allow_nil: false
    parameter :id, :number, required: true
    let(:dialogue_id){@dialogue.id}
    let(:variable_id){@variable.id}
    let(:option_id){@option.id}
    let(:id){@response_for_variable.id}
    example "delete response of variable" do
        do_request
    end
  end



end
