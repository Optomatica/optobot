
 This is a detailed instructions to create a bot, by the end of this documentation you will be abe to build your own chatbot.    



1. Firstly you have to sign-up/create user  
    using curl  

        curl "http://localhost:3000/auth" -d '{"email":"user_1@optomatica.com", "password":"password",
        "password_confirmation":"password"}' -X POST \
        -H "Content-Type: application/json" \

    or using rails console  

        @user = User.create!(:email => 'user_1@optomatica.com' , :password => 'password', :password_confirmation => 'password')

       
2. Then you have to sign in 
    
        curl "http://localhost:3000/auth/sign_in" -d '{"email":"user_1@optomatica.com", "password":"password"}' -X POST -H "Content-Type: application/json" -v

    you will get a response with all your authentication data 


        > POST /auth/sign_in HTTP/1.1
        > Host: localhost:3000
        > User-Agent: curl/7.47.0
        > Accept: */*
        > Content-Type: application/json
        > Content-Length: 53
        > 
        * upload completely sent off: 53 out of 53 bytes
        < HTTP/1.1 200 OK
        < X-Frame-Options: SAMEORIGIN
        < X-XSS-Protection: 1; mode=block
        < X-Content-Type-Options: nosniff
        < Content-Type: application/json; charset=utf-8
        < access-token: GA2ZRFU1v4n250kmBJU3cA
        < token-type: Bearer
        < client: fbpRgD16WQwe1rTatw4cEw
        < expiry: 2773642928
        < uid: user_1@optomatica.com
        < ETag: W/"28e8abac645cbc82cc780047671b8ff5"
        < Cache-Control: max-age=0, private, must-revalidate
        < X-Request-Id: 0d0abd6c-41ff-4fff-b378-3f7ae8e986aa
        < X-Runtime: 0.365133
        < Vary: Origin
        < Transfer-Encoding: chunked





2. You now can to validate the user

    using curl   
    don't forget to replace {Access-Token, Token-Type, Client, Expiry, Uid } with your own values 

        curl -g "http://localhost:3000/auth/validate_token" -X GET \
            -H "Access-Token: GA2ZRFU1v4n250kmBJU3cA" \
            -H "Token-Type: Bearer" \
            -H "Client: fbpRgD16WQwe1rTatw4cEw" \
            -H "Expiry: 2773642928" \
            -H "Uid: user_1@optomatica.com" \
            -H "Content-Type: application/json" \
    
    or using rails console  

        @new_auth_header = @user.create_new_auth_token()

3. you have to create you own wit app and get your Server Access Token  
    [ click for more details ](https://beta.optobot.ai/documentation#/NLP_Engine?id=train-your-nlu-engine)


3. Create new project  
     don't forget to replace "nlp_engine" with your own Server Access Token


    using curl   

        curl "http://localhost:3000/users/1/projects/create" -d '{"name":"project_1","nlp_engine":{"en":"NZ3FCS4UXPXPG7VI7XE2YZI5DXOXIEOI"},"external_backend":{},"is_private":false,"fallback_setting":{"fallback_counter_limit":3},"facebook_page_access_token":"string"}' -X POST \
    
    or using rails console   
      
        @project = Project.create!(name: "project_1" , nlp_engine: {en: "NZ3FCS4UXPXPG7VI7XE2YZI5DXOXIEOI"})
        @user_project = UserProject.create!(user_id: @user.id, project_id: @project.id, role: "admin")




4. Create new context

    using curl

        curl "http://localhost:3000/contexts/create" -d '{"project_id":1,"name":"first_context"}' -X POST \

    or using rails console

       @context = Context.create!(project_id: @project.id, name: "first_context")




5. Create new dialogue


        curl "http://localhost:3000/dialogues/create" -d '{"context_id":1,"project_id":1,"tag":"test","name":"dialogue_1","parents_ids":[] , "intent": "Greeting"}' -X POST \

   or using rails console

        @dialogue_1 = Dialogue.create!(project_id: @project.id, name: "dialogue_1", context_id: @context.id, tag: "dialogue_1" )


6. Create new response for of the dialogue

        curl "http://localhost:3000/dialogues/1/responses/create" -d '{"response_owner_id": 1 , "response_owner_type": "Dialogue"}' -X POST \

   or using rails console

        @response = Response.create!(response_owner_id: @dialogue_1.id, "response_owner_type": "dialogue")


7. Create a content for the response


        curl "http://localhost:3000/dialogues/1/responses/1/response_contents/create" -d '{"content":{"en":"Hi, how can I help you?"},"content_type":"text"}' -X POST \

   or using rails console


        @response_content = ResponseContent.create!(response_id: @response.id, content: {"en" => "Hi, how can I help you?"}, content_type:0)  # content_type = text

 


8. Start chatting with your bot

        curl "http://localhost:3000/projects/1/chatbot" -d '{"debug_mode":true,"text":"hi","email":"user_1@optomatica.com","language":"en","project_id":1}' -X POST \
 

    you will get this response

        {"dialogue":{"responses":[]},"variable":{"responses":[{"text":"Hi, how can I help you? "}],"options":[null]},"user_chatbot_session":{"id":1,"context_id":1,"dialogue_id":1,"created_at":"2019-06-27T10:04:14.623Z","updated_at":"2019-07-08T09:31:02.105Z","quick_response_id":null,"fallback_counter":0,"prev_session_id":null,"next_session_id":null}}


1. In the same project you can create a new context and dialogues with children (dialogue has children/variables)  

        repeat step 6 to create a new context   
        and repeat step 7 to create a new dialogue 

       


2. Create a variable  

        curl "http://localhost:3000/dialogues/2/variables/create" -d '{"project_id":1,"name":"Age_var","storage_type":"normal","source":"collected","allow_writing":true,"entity":"age_of_person"}' -X POST \

   or using rails console 
        
        @variable = Variable.create!(name: "Age_var", dialogue_id: @dialogue_1.id , project_id: @project.id , possible_values: [] , expire_after: nil  , save_text: false , entity: nil , storage_type: "in_cache", source: "collected" )


3. Create new response for the variable

        curl "http://localhost:3000/dialogues/2/variables/1/responses/create" -d '{"response_owner_id": 1 , "response_owner_type": "Variable"}' -X POST \

   or using rails console 

        @response_variable = Response.create!(response_owner_id: @variable.id, "response_owner_type": "variable")

           

4. Create a content for the variable response

        curl "http://localhost:3000/dialogues/2/variables/1/responses/2/response_contents/create" -d '{"content":{"en":"Hi, How old are you ? "},"content_type":"text"}' -X POST \

    or using rails console 

        @response_content_variable = ResponseContent.create!(response_id: @response_variable.id, content: {"en" => "Hi, How old are you ? "}, content_type:0)  # content_type = text



5. Create a child dialogue (in our case it's the second and last dialogue, so you don't have to create a variable for this dialogue)

        repeat step 7 to create a new dialogue

 

7. Create new response for the dialogue


        repeat step 8 to create a response for the dialogue
           

8. Create a content for the dialogue response

        repeat step 9 to create a new content for the dialogue response 
           

                  
5. create an new arc to connect the previous two dialogues

    or using rails console 

        @arc = Arc.create!(parent_id: @dialogue_2.id, child_id: @dialogue_3.id)


6. Create parameter (parameter of the condition on the arc that is connecting two dialogues)
Optobot can't redirect to the next dialogue unless this condition is satisfied

        curl "http://localhost:3000/arcs/1/parameters/create" -d '{"project_id":1 ,"value":"","min":"20","max":"29"}' -X POST \
        -H "Access-Token: SPVdYpH3NNq1QPUhoZsjLQ" \

     or using rails console

        @parameter = Parameter.create!(project_id: @project.id , min: "20" , max: "29")

               

6. create a new condition with your parameter 
   
    or using rails console

        Condition.create!( arc_id: @arc.id , variable_id: @variable.id, parameter_id: @parameter.id )



9. Start chatting with your bot

        curl "http://localhost:3000/projects/1/chatbot" -d '{"debug_mode":true,"text":"hi","email":"user_1@optomatica.com","language":"en"}' -X POST \
           

    you will get this response

        {"dialogue":{"responses":[]},"variable":{"responses":[{"text":"Hi, How old are you ? "}],"options":[null]},"user_chatbot_session":{"id":2,"context_id":2,"dialogue_id":2,"created_at":"2019-06-27T10:04:14.623Z","updated_at":"2019-07-08T09:31:02.105Z","variable_id":1,"quick_response_id":null,"fallback_counter":0,"prev_session_id":null,"next_session_id":null}}

    try to answer the bot question

       curl "http://localhost:3000/projects/1/chatbot" -d '{"debug_mode":true,"text":"25","email":"user_1@optomatica.com","language":"en"}' -X POST \
           

    you will get this response

        {"dialogue":{"responses":[]},"variable":{"responses":[{"text":"you are in your twenties. "}],"options":[null]},"user_chatbot_session":{"id":2,"context_id":2,"dialogue_id":2,"created_at":"2019-06-27T10:04:14.623Z","updated_at":"2019-07-08T09:31:02.105Z","variable_id":2,"quick_response_id":null,"fallback_counter":0,"prev_session_id":null,"next_session_id":null}}
