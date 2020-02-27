require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'

  resource "Contexts" do

    context 'contexts' do

    after(:all) do
        User.destroy_all 
        Project.destroy_all
        UserProject.destroy_all
        Dialogue.destroy_all
        Context.destroy_all
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
    #       do_request
    #   end 
    # end

    get "/contexts/:id/show" do
      parameter :id , "context's id" 
      let(:id){@context.id}
      example "show Context" do
          do_request
      end
    end
    
    get "/contexts/list" do
      parameter :project_id , "project's id" ,required: true
      let(:project_id){@project.id}
      example "list Context" do
      do_request
      end
    end
  
    get "/contexts/:id/has_dialogues" do
      parameter :id , "context's id" , required: true
      let(:id){@context.id}
      example "list all dialogues of the context" do
      do_request
      end
    end

    post "/contexts/create" do
      parameter :project_id , "project's id" , :number, required: true
      parameter :name , "context's name" , String
      let(:raw_post){{
          project_id: @project.id,
          name: "my context"
      }.to_json}
      example "create context" do
        do_request
      end
    end


    put "/contexts/:id/update" do
      parameter :id , "project's id" , required: true
      parameter :name , "context's name"

      let(:id){@context.id}
      let(:raw_post){{
          name: "my context"
      }.to_json}

      example "update context" do
      do_request
      end
    end
    
    delete "/contexts/:id/destroy" do
      parameter :id , "project's id" , required: true
  
      let(:id){@context.id}

      example "delete context" do
        do_request
      end
    end

    end
  end



