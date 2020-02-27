namespace :example do

    # run it by this command
    # "  bundle exec rake environment example:Chatting["project_seed_153","user_seed_153@example.com"]  "

    desc "Chatting"
    task :Chatting, [:project_name, :email ] do |task, args|
        puts "start Chating.... "
        auth_token = User.last.create_new_auth_token()
        STDOUT.puts "Start chatting with your bot, say => [ Hi ]  or type your intent "
        while user_input = STDIN.gets.chomp # loop while getting user input
            case user_input
            when ""
                next
            else
                formResponse = nil
                if user_input[0] == "{"
                    formResponse = user_input
                    user_input = nil
                end
                Project.last.send_request(user_input , formResponse ,Project.last.id , auth_token['access-token'] , auth_token['client']  , auth_token['expiry'] , auth_token['uid'])
            end
        end
    end
end

