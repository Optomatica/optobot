namespace :optobot do

    # run it by this command"   bundle exec rake environment optobot:initial_create\["project_name","user@example.com"\]
    desc " initial_create"
    task :initial_create, [:project_name, :email ] do |task, args|
      include WitHelper

      p args['project_name']
      puts " initial_create task ........... "
      # create user
      @user = User.find_by_email(args['email']) || User.create!(:email => args['email'] , :password => 'password', :password_confirmation => 'password')
      # validate user
      @new_auth_header = @user.create_new_auth_token()
      # create project
      project_params = { name: args['project_name'] , nlp_engine: {en: ENV['WIT_SERVER_TOKEN']} }
      @project = Project.create!(project_params)
      @project.prod_project = Project.create!(project_params)
      @project.save!

      UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")

      p " Authentication data " , @new_auth_header
      p " project_id = " , @project.id
      response = create_wit_app(args['email'].split('@')[0] + '_' + args['project_name'] )

      p " access_token == " , response['access_token']
      @project.update!(nlp_engine: {en: response['access_token'] || ENV['WIT_SERVER_TOKEN']})
      p " project created ....... ", @project
    end

    # run it by this command "  bundle exec rake environment optobot:wit_train "
    desc "wit training"
    task :wit_train do
      puts "training wit ...."
      wfile = File.new(Rails.root.join("train/wit_training.optonlp"))
      file = wfile.read
      Project.where.not(prod_project_id: nil).last.parse_nlp_file_and_train_wit(file, 'en')
    end


       # run it by this command "  bundle exec rake environment optobot:destroy "
    desc "destroy"
    task :destroy do
        puts "destroying...."
        project = Project.where.not(prod_project_id: nil).last
        project.variables.destroy_all
        project.contexts.destroy_all
        project.dialogues.where(tag: nil).destroy_all

        p "destroyed"
    end

    # run it by this command "  bundle exec rake environment optobot:Train "
    desc "Train"
    task :Train do
        puts "destroying...."
        project = Project.where.not(prod_project_id: nil).last
        project.user_projects.each{|up| up.user_chatbot_session && up.user_chatbot_session.destroy}
        project.variables.destroy_all
        project.contexts.destroy_all
        project.dialogues.where(tag: nil).destroy_all
        puts "Training task.... "

        Dir.foreach("train/") do |item|
            unless (item == ".") || (item == "..")
            p item
                wfile = File.new(Rails.root.join("train/#{item}"))
                file = wfile.read

                if File.extname(item) == ".optonlp"
                    project.parse_nlp_file_and_train_wit( file ,"en" )
                elsif File.basename(item).include? "no_context" and File.extname(item) == ".optodsl"
                    project.import_context_dialogues_data( file , nil, "en" )
                elsif File.extname(item) == ".optodsl"
                    context = Context.create!(project_id: project.id, name: "my_context")
                    project.import_context_dialogues_data( file , context.id, "en" )

                end
            end
        end
    end


end

