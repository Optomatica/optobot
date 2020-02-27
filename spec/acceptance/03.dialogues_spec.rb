require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'

resource "Dialogues" do

  context 'dialogues' do

  after(:all) do
      User.destroy_all 
      Project.destroy_all
      UserProject.destroy_all
      Dialogue.destroy_all
  end

  before (:all) do
    @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
    @new_auth_header = @user.create_new_auth_token()
    @project = Project.create!()
    @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")
    @context = Context.create!(name: "my_context" , project_id: @project.id)
    @dialogue = Dialogue.create!(project_id: @project.id, name: "good_dialogue", tag: "test")
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
    
    get "/dialogues/:id/show" do
      parameter :id , "dialogue's id" 
      let(:id){@dialogue.id}
      example "show Dialogues" do
        do_request
      end
    end
      

    post "/dialogues/list" do
      parameter :project_id, :number, required: true
      parameter :context_id, :number
      let(:raw_post){{
        context_id: @context.id,
        project_id: @project.id
      }.to_json}
      example "list dialogues" do
        do_request
      end
    end


    post "/dialogues/create" do
      parameter :context_id, :number
      parameter :project_id, :number, required: true
      parameter :tag, String
      parameter :intent, String
      parameter :name, String, required: true, allow_nil: false
      parameter :parents_ids, Array, of: Integer, desc: "simple array of numbers (parents ids)"
      let(:raw_post){{
        context_id: @context.id,
        project_id: @project.id,
        tag: "testtest",
        name: "my dialogue",
        parents_ids: Dialogue.all.pluck(:id)
      }.to_json}

      example "create dialogue" do
        do_request
      end
    end
    

    put "/dialogues/:id/update" do
      parameter :id, :number, required: true
      parameter :project_id, :number, required: true
      parameter :context_id, :number
      parameter :tag, String
      parameter :intent, String
      parameter :name, String, allow_nil: false
      parameter :added_parents, Array, of: Integer, desc: "simple array of numbers (parents ids to add its relations)"
      parameter :removed_parents, Array, of: Integer, desc: "simple array of numbers (parents ids to remove its relations)"
      
      let(:raw_post){{
        context_id: @context.id,
        project_id: @project.id,
        tag: "testtest",
        name: "my dialogue",
        added_parents: Dialogue.all.pluck(:id),
        removed_parents: Dialogue.all.pluck(:id)
      }.to_json}

      let(:id){@dialogue.id}

      example "update dialogue" do
        do_request
      end
    end
    
    delete "/dialogues/:id/destroy" do
      parameter :id, :number, required: true
      let(:id){@dialogue.id}
        
      example "delete dialogue" do
        do_request
      end
    end

  end
end



