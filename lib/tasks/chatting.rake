namespace :example do

    # run it by this command
    # "  bundle exec rake environment example:Chatting "

    desc "Chatting"
    task :Chatting do
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
                send_request(user_input, formResponse, Project.where(test_project_id: nil).last.id, auth_token['access-token'], auth_token['client'], auth_token['expiry'], auth_token['uid'])
            end
        end
    end

    def send_request(text, formResponse, project_id, access_Token, client, expiry, uid)
        require 'uri'
        require 'net/http'
        url = URI("http://localhost:3000/projects/#{project_id}/chatbot")
        http = Net::HTTP.new(url.host, url.port)
        
        request = Net::HTTP::Post.new(url)
        request["Access-Token"] = access_Token
        request["Token-Type"] = 'Bearer'
        request["Client"] = client
        request["Expiry"] = expiry
        request["Uid"] = uid
        request["Content-Type"] = 'application/json'
        formResponse = formResponse.to_json unless formResponse.present?
        request.body = "{\"debug_mode\": true ,\"text\":\"#{text}\" ,\"formResponse\":#{formResponse} ,\"language\":\"en\" , \"email\":\"#{uid}\"}\n"
        
        response = http.request(request)
        res = JSON.parse(response.read_body)
        
        if  res['dialogue'].present?
            res['dialogue']['responses'].each do | response_type, response_content |
              puts "#{response_type}: #{response_content}"
            end
          
        end
        if  res['variable'].present?
          res['variable']['responses'].each do | response_type, response_content |
            puts "#{response_type}: #{response_content}"
          end
          
          res['variable']['options'].length.times do |i|
            p " => #{res['variable']['options'][i]['text']} "
          end
          
        end
        if res['form'].present?
          res['form'].length.times do |i|
            res['form'][i]['responses'].length.times do |j|
              p res['form'][i]['responses'][j]['text']
            end
            
            res['form'][i]['options'].length.times do |j|
              p res['form'][i]['options'][j]['text']
            end
          end
        end
      end
end

