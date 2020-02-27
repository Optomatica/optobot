require 'acceptance_helper'


resource "Variable" do

  after(:all) do
    User.destroy_all
    Project.destroy_all
    UserProject.destroy_all
    Dialogue.destroy_all
    Option.destroy_all
    Variable.destroy_all
    Context.destroy_all
  end

  before (:all) do
    @user = User.create!(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password')
    @new_auth_header = @user.create_new_auth_token()
    @project = Project.create!()
    @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")
    @context = Context.create!(name: "my_context" , project_id: @project.id)
    @dialogue = Dialogue.create!(project_id: @project.id, name: "good_dialogue", tag: "test")
    @variable = Variable.create!(name: "variable_name", dialogue_id: @dialogue.id , project_id: @project.id)
    @option = Option.create!(variable_id: @variable.id)
  end

  before(:each) do
    header "access-token", @new_auth_header["access-token"]
    header "token-type", @new_auth_header["token-type"]
    header "client", @new_auth_header["client"]
    header "expiry", @new_auth_header["expiry"]
    header "uid", @new_auth_header["uid"]
    header "Content-Type", "application/json"
  end


  get "/dialogues/:dialogue_id/variables/:id/show" do
    parameter :dialogue_id, :number, required: true
    parameter :id, :number, required: true
    parameter :project_id, :number, required: true

    let(:dialogue_id){@dialogue.id}
    let(:id){@variable.id}
    let(:project_id){ @project.id}
    example "show variable of the current dialogue with its messages and options " do
        do_request
    end
  end


  get "/dialogues/:dialogue_id/variables/list" do
    parameter :dialogue_id, :number, required: true
    parameter :id, :number, required: true
    parameter :project_id, :number, required: true

    let(:dialogue_id){@dialogue.id}
    let(:id){@variable.id}
    let(:project_id){@project.id}
    example "list all variables of the project " do
        do_request
    end
  end


  post "/dialogues/:dialogue_id/variables/create" do
    parameter :dialogue_id, :number, required: true
    parameter :project_id, :number, required: true
    parameter :name, String
    parameter :expire_after, :number
    parameter :storage_type, String, disc: "normal, timeseries, in_session , timeseries_in_cache or in_cache"
    parameter :source, String, disc: "collected, fetched or provided"
    parameter :allow_writing, :boolean
    parameter :entity, String
    parameter :possible_values, Array, of: String
    parameter :allowed_range, Hash, disc: "with keys 'min' and 'max'"
    parameter :fetch_info, Hash

    let(:dialogue_id){@dialogue.id}
    let(:raw_post){{
      project_id: @project.id,
      name: "city name",
      expire_after: 5,
      storage_type: "normal",
      source: "collected",
      allow_writing: true,
      entity: "location",
      possible_values: ["cairo","alex"],
      allowed_range: nil ,
      #fetch_info: { url: "https://www.google.com", key: 'weather' }
      # fetch_info: {function: 'is_city', arguments: ['cairo']}
      # fetch_info: {function: 'weather', arguments: [{variable: 123}]}
      # fetch_info: {function: 'weather', arguments: ['Cairo']}
      # fetch_info: {function: 'add', arguments: [{variable: 123}, {variable: 124}]}
      # fetch_info: {function: 'add', arguments: [{variable: 123}, 14]}
      }.to_json}
    example "create new variable for the current dialogue" do
        do_request
    end
  end




  put "/dialogues/:dialogue_id/variables/:id/update" do
    parameter :id, :number, required: true
    parameter :dialogue_id, :number, required: true, allow_nil: false
    parameter :project_id, :number, required: true
    parameter :name, String
    parameter :expire_after, :number
    parameter :storage_type, String, disc: "normal, timeseries, in_session , timeseries_in_cache or in_cache"
    parameter :source, String, disc: "collected, fetched or provided"
    parameter :allow_writing, :boolean
    parameter :entity, String
    parameter :possible_values, Array, of: String
    parameter :allowed_range, Hash, disc: "with keys 'min' and 'max'"
    #parameter :fetch_info, Hash

    let(:id){@variable.id}
  let(:dialogue_id){@dialogue.id}
    let(:raw_post){{
      project_id: @project.id,
      name: "new name",
      expire_after: 5,
      storage_type: "normal",
      source: "collected",
      allow_writing: true,
      entity: "distance",
      possible_values: ["1","3","4"],
      allowed_range: { "min" => 1, "max" => 6 }
      #fetch_info: { link: " " }
    }.to_json}
    example "update variable" do
        do_request
    end
  end


  delete "/dialogues/:dialogue_id/variables/:id/destroy" do
    parameter :dialogue_id, :number, required: true , allow_nil: false
    parameter :id, :number, required: true
    parameter :project_id, :number, required: true

    let(:dialogue_id){@dialogue.id}
    let(:id){@variable.id}
    let(:raw_post){{
      project_id: @project.id
    }.to_json}
    example "delete variable by id" do
        do_request
    end
  end

end



