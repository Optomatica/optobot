require 'rails_helper'
require 'rspec_api_documentation/dsl'
require 'acceptance_helper'
require "spec_helper"
require 'rails_helper'
require 'date'


resource "Projects" do

    after(:all) do
      User.destroy_all
      UserChatbotSession.destroy_all
      Project.destroy_all
      UserProject.destroy_all
      Context.destroy_all
      Dialogue.destroy_all
      Variable.destroy_all
      ChatbotMessage.destroy_all
    end

    before (:all) do
      @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
      @add_user = User.create!(:email => 'add_test@example.com', :password => 'password', :password_confirmation => 'password')
      @remove_user = User.create!(:email => 'remove_test@example.com', :password => 'password', :password_confirmation => 'password')
      @new_auth_header = @user.create_new_auth_token()
      @project = Project.create!(nlp_engine: {en: "TMMHDH7GEWYZOPTWASAL2KCJ2HAXOPLJ"})
      prod_project = Project.create!()
      @project.prod_project = prod_project
      @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")
      @user_project = UserProject.create!(user_id: @remove_user.id, project_id: @project.id, role: "subscriber")
      @user_project = UserProject.create!(user_id: @remove_user.id, project_id: @project.prod_project.id, role: "admin")
      @context = Context.create!(name: "my_context" , project_id: @project.id)
      @dialogue = Dialogue.create!(project_id: @project.id, name: "good_dialogue", tag: "test")
      @parent_dialogue = Dialogue.create!(project_id: @project.id, name: "parent_dialogue", tag: "parent_test")
      @child_dialogue = Dialogue.create!(project_id: @project.id, name: "child_dialogue", tag: "child_test")
      @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id)
      @user_chatbot_session = UserChatbotSession.create!(context_id: @context.id, dialogue_id: @dialogue.id)
      @user_project.user_chatbot_session_id = @user_chatbot_session.id
      @user_project.save!
      @chatbotmessage = ChatbotMessage.create!(user_project_id: @user_project.id, message: "cgatbot message", is_user_message: false)
      @problem = @project.problems.create!(problem_type: :provided_data_missing , chatbot_message_id: @chatbotmessage.id )
      @user_message = ChatbotMessage.create!(user_project_id: @user_project.id, message: "hello", is_user_message: false)
      myfile = File.new(Rails.root.join("train/weather.optodsl"))
      @file = fixture_file_upload(myfile, 'text/plain')
      wfile = File.new(Rails.root.join("train/wit_training.optonlp"))
      @witfile = fixture_file_upload(wfile, 'text/plain')
      @emails = ["remove_test@example.com" ]

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


    post "/users/:user_id/projects/create" do
      parameter :user_id, :number, required: true
      parameter :name, String
      parameter :nlp_engine, Hash
      parameter :external_backend, Hash
      parameter :is_private, :boolean
      parameter :fallback_setting, Hash
      parameter :facebook_page_access_token, String
      let(:user_id){@user.id}
      let(:raw_post){{
        name: "my_project",
        nlp_engine: {en: "BMFLM7L7XWZQN5MVMSWUGOHAWSTC4B5U", sv: "CAPCDH3FHBE5USQMXAQA3RFF2L5FJAEU"},
        external_backend: {},
        is_private: false,
        fallback_setting: {"fallback_counter_limit"=>3},
        facebook_page_access_token: "string"
      }.to_json}

      example "create project" do
        do_request
        p response_body
      end
    end

    put "/users/:user_id/projects/:id/update" do
      parameter :user_id, :number, required: true
      parameter :id, :number, required: true
      parameter :name, String
      parameter :nlp_engine, Hash
      parameter :external_backend, Hash
      parameter :is_private, :boolean
      parameter :fallback_setting, Hash
      parameter :facebook_page_access_token, String
      let(:user_id){@user.id}
      let(:id){@project.id}
      let(:raw_post){{
        name: "my_project",
        nlp_engine: {en: "BMFLM7L7XWZQN5MVMSWUGOHAWSTC4B5U", sv: "CAPCDH3FHBE5USQMXAQA3RFF2L5FJAEU"},
        #external_backend: "",
        is_private: false,
        fallback_setting: {"fallback_counter_limit"=>3}
        #facebook_page_access_token:
      }.to_json}
      example "update project" do
        do_request
      end
    end



    # delete "/users/:user_id/projects/:id/destroy" do
    #   parameter :user_id, :number, required: true
    #   parameter :id, :number, required: true
    #   let(:user_id){@user.id}
    #   let(:id){@project.id}
    #   example "destroy project" do
    #     do_request
    #   end
    # end


    get "/users/:user_id/projects/:id/show" do
      parameter :id , "project's id" , :number #, required: true
      parameter :user_id , "user's id" , :number #, required: true
      let(:id){@project.id}
      let(:user_id){@user.id}

      example "show projects" do
        do_request
      end
    end


    get "/users/:user_id/projects/list" do
      parameter :user_id , "user's id" , :number #, required: true
      let(:user_id){@user.id}
      example "list projects" do
        do_request
      end
    end


    post "/projects/:id/update_session" do
      parameter :id, :number, required: true
      parameter :user_chatbot_session_id, :number, required: true
      parameter :context_id, :number
      parameter :dialogue_id, :number
      parameter :variable_id, :number
      parameter :quick_response_id, :number
      parameter :fallback_counter, :number
      parameter :prev_session_id, :number
      parameter :next_session_id, :number
      let(:id){@project.id}
      let(:raw_post){{
        user_id: @user.id,
        user_chatbot_session_id: @user_chatbot_session.id,
        context_id: @context.id,
        dialogue_id: @dialogue.id,
        variable_id: @variable.id,
        quick_response_id: @user_chatbot_session.quick_response_id,
        fallback_counter: @user_chatbot_session.fallback_counter,
        prev_session_id: @parent_dialogue.id,
        next_session_id: @child_dialogue.id }.to_json }
      example "update_session" do
          do_request
      end
    end

    # delete "/projects/:id/remove_problem" do
    #   parameter :user_id , "user's id" , :number , required: true
    #   parameter :id , "project's id" , :number , required: true
    #   parameter :problem_id, :number, required: true
    #   parameter :debug_mode, :boolean, default: true
    #   let(:id){@project.id}
    #   let(:user_id){@user.id}
    #   let(:raw_post){{
    #     problem_id: @problem.id,
    #     debug_mode: true
    #   }.to_json}
    #   example "remove_problem" do
    #     do_request
    #   end
    # end



    post "/users/:user_id/projects/:id/add_users_to_project" do
      parameter :user_id , "user's id" , :number , required: true
      parameter :id , "project's id" , :number , required: true
      parameter :role, String, "auther or subscriber"
      parameter :user_ids, Array
      parameter :user_emails, Array
      parameter :send_emails, :boolean
      let(:user_id){@user.id}
      let(:id){@project.id}

      let(:raw_post){{
        role: "admin",
        user_ids: @add_user.id,
        user_emails: [@add_user.email],
        send_emails: true

      }.to_json}
      example "add users to project" do
        do_request
      end
    end

    post "/users/:user_id/projects/:id/remove_users_from_project" do
      parameter :user_id , "user's id" , :number , required: true
      parameter :id , "project's id" , :number , required: true
      parameter :emails, Array, of: String
      let(:id){@project.id}
      let(:user_id){@user.id}
      let(:raw_post){{
        emails: @emails  #["remove_test@example.com" ]
      }.to_json}
      example "remove users to project" do
        do_request
      end
    end



     get "/users/:user_id/projects/:id/list_project_users" do
      parameter :user_id , "user's id" , :number , required: true
      parameter :id , "project's id" , :number , required: true
      let(:id){@project.id}
      let(:user_id){@user.id}
      example "list user's projects" do
        do_request
      end
    end

    get "/projects/:id/get_chat_problems" do
      parameter :id , "project's id" , :number , required: true
      parameter :debug_mode, :boolean, default: false
      let(:id){@project.id}
      let(:debug_mode){true}
      example "get the problems of the project" do
        do_request
      end
    end

    # post "/projects/:id/get_chat_messages" do
    #   parameter :id , "project's id" , :number , required: true
    #   parameter :email, String, required: true, desc: "the email of the user that signed-in by the account admin"
    #   parameter :limiting_number, :number
    #   parameter :date, Date
    #   let(:id){@project.id}
    #   let(:raw_post){{
    #     email: @user.email,
    #     limiting_number: 5,
    #     date: Time.utc(2000).to_f
    #   }.to_json}
    #   example "get the meesages of the user and the bot by number limit or starting date" do
    #     do_request
    #   end
    # end


    get "/projects/:id/export_dialogues_data" do
      parameter :id , "project's id" , :number , required: true
      let(:id){@project.id}
      example "export dialogues data" do
        do_request
      end
    end

    post "/projects/:id/import_context_dialogues_data" do
      parameter :id , "project's id" , :number , required: true
      parameter :context_id, Integer
      parameter :file , File, required: true , default: " example file for description of a proposed language we can use directly to implement it easily
          [  See documentation for DSL examples ]"
      let(:id){@project.id}
      let(:context_id){@context.id}
      let(:file){@file}
      header "Content-Type", "application/x-www-form-urlencoded"
      example "import dialogues data from file" do
        do_request
      end
    end


    post "/projects/:id/train_wit" do
      parameter :lang, String, required: true
      parameter :file , File, required: true , default: " https://docs.google.com/document/d/1HFcPB8FSo_tyJ3Ypql46c7vYltnxP-CHZIkHxYDkGso/edit?usp=sharing "
      let(:id){@project.id}
      let(:lang){"en"}
      let(:file){@witfile}
      header "Content-Type", "application/x-www-form-urlencoded"
      example "training wit" do
        do_request
      end
    end

end
