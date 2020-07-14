namespace :example do

  # run it by this command "  bundle exec rake environment example:MyFirstProject user_email=user@example.com project_name=my_first_project"
  desc "Create an example project with contexts and dialogues"
  task :MyFirstProject do
    include WitHelper

    @user = User.create!(:email => ENV["user_email"] , :password => 'password', :password_confirmation => 'password')
    @new_auth_header = @user.create_new_auth_token()

    project_params = { name: ENV["project_name"] , nlp_engine: {en: ENV['WIT_SERVER_TOKEN']} }
    @project = Project.create!(project_params)

    @project.prod_project = Project.create!(project_params)
    @project.save!

    @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")

    wit_response = create_wit_app(@project.name)
    @project.update!(nlp_engine: {en: wit_response['access_token']})
    @context = Context.create!(project_id: @project.id, name: "context_seed")


    newcontext = Context.create!(project_id: @project.id, name: "first_context")
    new_dilog = Dialogue.create!(project_id: @project.id , name: "first dialogue", context_id: newcontext.id, action: nil)
    response=Response.create!(response_owner: new_dilog, order: 1)
    ResponseContent.create!(response_id: response.id, content: {"en" => "Hi , how can I help you ? "}, content_type:0)


    @dialogue_1 = Dialogue.create!(project_id: @project.id, name: "watch_movie", context_id: @context.id, tag: "dialogue_1" )

    @intent =Intent.create!(dialogue_id: @dialogue_1.id , value: "bored")
    @variable_watch_movie_V1 = Variable.create!(name: "watch_movie", dialogue_id: @dialogue_1.id , project_id: @project.id , possible_values: ["ok" , "no thanks" ] , expire_after: nil  , save_text: false , entity: nil , storage_type: "in_cache", source: "collected" )
    @response_V1 = Response.create!(response_owner_id: @variable_watch_movie_V1.id, "response_owner_type": "Variable")
    @response_content_V1 = ResponseContent.create!(response_id: @response_V1.id, content: {"en" => "what about watching a movie ?"}, content_type:0)  # content_type = text

    @option_V1_ok = Option.create!(variable_id: @variable_watch_movie_V1.id, value: "Ok" )
    @response_content_V3_Y = ResponseContent.create!(response_id: @option_V1_ok.response.id, content: {"en" => "Ok"}, content_type:0)  # content_type = text
    @option_V1_no = Option.create!(variable_id: @variable_watch_movie_V1.id, value: "No Thanks" )
    @response_content_V3_N = ResponseContent.create!(response_id: @option_V1_no.response.id, content: {"en" => "No Thanks"}, content_type:0)  # content_type = text


    @dialogue_2 = Dialogue.create!(project_id: @project.id, name: "Age", context_id: @context.id, tag: "dialogue_2")
    @variable_age_V2 = Variable.create!(name: "age", dialogue_id: @dialogue_2.id , project_id: @project.id , possible_values: nil , expire_after: nil  , save_text: false , entity: "number" , storage_type: "in_cache", source: "collected" )
    @response_V2 = Response.create!(response_owner_id: @variable_age_V2.id, "response_owner_type": "Variable")
    @response_content_V2 = ResponseContent.create!(response_id: @response_V2.id, content: {"en" => "I need to know your age "}, content_type:0)  # content_type = text


    @dialogue_3 = Dialogue.create!(project_id: @project.id, name: "play_exercise", context_id: @context.id, tag: "dialogue_3" )
    @response_D3 = Response.create!(response_owner_id: @dialogue_3.id, "response_owner_type": "Dialogue")
    @response_content_D3 = ResponseContent.create!(response_id: @response_D3.id, content: {"en" => "try to play some fitness exercises."}, content_type:0)  # content_type = text


    @dialogue_4 = Dialogue.create!(project_id: @project.id, name: "horror_movies", context_id: @context.id, tag: "dialogue_4" )
    @response_D4 = Response.create!(response_owner_id: @dialogue_4.id, "response_owner_type": "Dialogue")
    @response_content_D4 = ResponseContent.create!(response_id: @response_D4.id, content: {"en" => "watching a horror movie will make you scary and not bored at all :D we recommend you [Annabelle] or [The conjuring]"}, content_type:0)  # content_type = text


    @dialogue_5 = Dialogue.create!(project_id: @project.id, name: "animation_movies", context_id: @context.id, tag: "dialogue_5" )
    @response_D5 = Response.create!(response_owner_id: @dialogue_5.id, "response_owner_type": "Dialogue")
    @response_content_D5 = ResponseContent.create!(response_id: @response_D5.id, content: {"en" => "watching an animation movie will make you happy :D we recommend you [Up] or [Inside out] "}, content_type:0)  # content_type = text


    @arc_2 = Arc.create!(parent_id: @dialogue_1.id, child_id: @dialogue_2.id)
    @arc_3 = Arc.create!(parent_id: @dialogue_1.id, child_id: @dialogue_3.id)

    @arc_4 = Arc.create!(parent_id: @dialogue_2.id, child_id: @dialogue_4.id)
    @arc_5 = Arc.create!(parent_id: @dialogue_2.id, child_id: @dialogue_5.id)


    Condition.create!( arc_id: @arc_2.id , variable_id: @variable_watch_movie_V1.id, option_id: @option_V1_ok.id )
    Condition.create!( arc_id: @arc_3.id , variable_id: @variable_watch_movie_V1.id, option_id: @option_V1_no.id )


    @parameter = Parameter.create!(project_id: @project.id , min: "20" , max: "50")
    Condition.create!( arc_id: @arc_4.id , variable_id: @variable_age_V2.id, parameter_id: @parameter.id )



    @parameter = Parameter.create!(project_id: @project.id , min: "3" , max: "19")
    Condition.create!( arc_id: @arc_5.id , variable_id: @variable_age_V2.id , parameter_id: @parameter.id)

    p  " user_id = " , @user.id
    p " Authentication data " , @new_auth_header
    p " project_id = " , @project.id
    p  "wit _response = " , wit_response
    p " access_token == " , wit_response['access_token']


  end
end
