# __Quick Start__


1.Installation
--------------

First you need to clone the Optobot repository. Cloning a repository sync it to your local machine.  
These instructions show you how to clone the repository using Git.

  1. Open a new terminal window.
  
  2. From the terminal window, change to a local directory where you want to clone the repository.

  3. Paste this command to clone:

          `$ git clone git@github.com:Optomatica/optobot.git`

      If the clone was successful, a new sub-directory will appear on your local drive in the directory where you cloned the repository. This directory will be named **optobot**.

  4. Make sure you have Ruby 2.6.1 or later and go to the project root and install project dependencies.

	`bundle install`

  5. Setup the database by running this command.

	`rake db:setup`
   
2.NLP Training
------------------
Chatbots usually carry out conversations with users. When building a chatbot, the aim is to understand the ‘intent’ of a user’s utterance that can then be used to guide the dialogue between the chatbot and the user. Training the chatbot to understand certain statements, is simplified in Optobot through the use of files. Since Optobot uses wit.ai, there are other ways to train the bot which are further explained [here](/NLP_Engine). To define an intent such as ‘greeting’ and some examples of that intent to be used for training, the developer can add statements with the below syntax, to the file ‘wit_training.optonlp’ 

   __[I:intent_value]__ The line including this syntax is used to define the name of your intent, which groups messages of the same meaning with the intent_value specified. The intent_value is a string containing the name of the intent that you want. All the subsequent sentences until the next intent declaration statement will correspond to the defined intent_value when the user types any of these sentences or sentences similar to them.
    All the files with `.optonlp` extension will be used to train __WIT.ai__ so that it can recognize similar statements and match them to the correct intent. 

This is an example of ‘wit_training.optonlp’ that trains ["hi" , "hey" , "hello"] as "Greeting" intent

```
[I:Greeting]
Hi
Hey
Hello

```

More examples:    

```
[E:wit$number]
1000
-56
5.369
10,000
30%

[I:purchase_flowers]
flower
flowers
buy flowers
purchase flowers
bouquet

```



3.Dialogue Training
------------------ 
Now that the bot can understand intents, we can start designing the user/bot dialogue. 

__Example__     
            This example implements this diagram.
            ![Diagram image local ](/assets/images/buy_flowers.jpg)
        You can use either method of the upcoming two methods 

### 3.1 Using Optobot’s DSL
------------
This is a description of a proposed language that OptoBot uses for easier implementation. The file extension is __.optodsl__. Next is an example of a simple opto DSL file. When the user's intent is __flowers__, optobot asks user about his.her budget and the conversation then goes as follows:

```
[N:buy_flowers:purchase_flowers]
[V:flowers_budget:number] Lovely! What is your budget?
[F:flowers_count:number:in_session] int_division(flowers_budget,2)

[C:low_budget] flowers_budget=[2-30] & flowers_count
[C:medium_budget] flowers_budget=[31-70]
[C:high_budget] flowers_budget=[71-]


[N:low_budget] (response) Great!, you can buy {{flowers_count}} rose(s)
(response) image@https://images.pexels.com/photos/736230/pexels-photo-736230.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260

[N:medium_budget]
[V:flower_type_medium] Please choose what kind of flowers you would like in your flower arrangement?
[O]Roses
[O]Tulipes
[O]Sunflowers

[C:roses_option] flower_type_medium=Roses
[C:tulipes_option] flower_type_medium=Tulipes
[C:sunflowers_option] flower_type_medium=Sunflowers

[N:roses_option] (response) Great choice! You have selected a flower bouquet consisting of 18 Long Stemmed Red Roses.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/30047878_40065_LOL?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin

[N:tulipes_option] (response) Great choice! Nothing beats a big bunch of tulips fresh from the fields. These 30 tulips deliver an undeniably bright burst of color into any setting, whether it's a window sill or a country table.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/3669_TOP?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin

[N:sunflowers_option] (response) Great choice! Ten sunflowers with big, bright heads just change the feeling of a room: suddenly, everything seems a bit brighter.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/41220_30213783_LOL?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin


[N:high_budget]
[V:flower_type_high] Please choose what kind of flowers you would like in your flower arrangement?
[O]White Roses
[O]Lilies
[O]Orchid

[C:white_roses_option] flower_type_high=White Roses
[C:lilies_option] flower_type_high=Lilies
[C:orchid_option] flower_type_high=Orchid


[N:white_roses_option] (response) Great choice! the beauty of white roses is unchallenged. Representing innocence, their versatility makes them a favorite gift to offer congratulations for graduation, engagements, bridal showers, new baby, or even a gift of sympathy.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/30184713_LOL?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin

[N:lilies_option] (response) Great choice! Let them know how much you care with a gorgeous bouquet that features carnations, stock, roses, lilies and Fuji mums. Each bloom is a thoughtful reminder of your support and love, while sitting in a beautifully crafted basket.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/S5272P_LOL?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin

[N:orchid_option] (response) Great choice! The Glowing Strong Orchid Plant offers a fresh warmth and beauty that your special recipient will treasure.
(response) image@https://s7img.ftdi.com/is/image/ProvideCommerce/PO58_LOL?$proflowers-hero-lv-new$&qlt=80,0&resMode=trilin

```


1. __[N&#58;dialogue_name&#58;dialogue_intent]__ Lines using this syntax represent a start of a block that may involve multiple variables/questions. This to mark a case where Optobot collects information from the user by asking one or more question(s).
    The dialogue_name is just an identifier to this block. This identifier can be used later on to instruct Optobot to go to this block if needed in certain conditions. This will be discussed in more details in conditions.
    Also, you can optionally assign the dialogue's intent that will inform Optobot to go to this section if the specified intent is detected.   
    Also you can write responses that Optobot would say to the user. It is optional if this Node has variables, otherwise it should have at least one response.   

2. __[V&#58;variable_name:variable_type&#58;variable_storage_type]__ This syntax represents a declaration of a variable that belongs to the previously declared block `[N:]`. 
   variable_name is the name you want to have for this variable. The variable_name can be used later on in statements or conditions
   You can optionally assign the variable_type and variable_storage_type.  
   
    After this syntax, you should write the response `statement` that optobot would say. The response that the user types in after the bot statement, is send to Wit.ai and the returned intent or option value is stored in this variable by optobot automatically. If you want to store the exact response of the user without sending a request to Wit.ai, you can do that by adding `save_text` in variable declararion [V&#58;variable_name:variable_type&#58;variable_storage_typee&#58;save_text]   

    Also in bot's response you can display value of a variable using two curly brackets. Example `Great!, you can buy {{flowers_count}} rose(s)`. For a time series variable, Optobot get the last stored value by default. If you want to get all values you can write `{{var_name.all}}`


3. __[O]__ This is an option. Options are quick replies suggestions that belong to a given variable. They are directly added by optobot after saying the variable statement. Options should be declared directly after a variable `[V]`. The user can then choose any of these options/quick replies instead of typing it.

4. __[C:dialogue_name] variable_name=variable_value__
    This is a condition declaration. A condition is an instruction for optobot to go to a certain statement or a block `dialogue_name` if a certain condition is met. The condition is represented by the variable_name and variable_value. If the variable with name = "variable_name" has a value = "variable_value", then this condition is met.
    In this case, Optobot would go to dialogue with name = “dialogue_name”  
   __variable_value__ can be one of the following:   
   - A number: this means that the variable value has to be exactly equal to this number.
   - A string: this means that the variable value (or intent) has to be equal to the specified string.
   -  [min_value-max_value]: this means that the variable value has to be within the range of these min_value and max_value numbers.
   -  [min_value- ]: if there is no max_value specified, then the variable value has to be larger than the min_value without having a maximum limit.
   - [ -max_value]: if there is no min_value specified, then the variable value has to be smaller than the max_value.
   - (empty): If the variable_value is not specified, then Optobot will just check for the presence of the variable in user's data regardless of it's value.

5. Computed or Fetched variables:   
    variable_name, variable_type and variable_storage_type works exactly like other variables `[V:]`  
    
    >__[F&#58;variable_name&#58;variable_type&#58;variable_storage_type] method_name(first_item, second_item, ...)__ 
    
    This is a computed variable. There are a set of predefined methods (like addition, subtraction and some other helper functions) that you can use them in `method_name`.    

    Items (first_item, second_item, etc…) are arguments to predefined Optobot functions. These items can be numbers, strings or variable names.   
    Example    
    `[F:flowers_count:number:in_session] int_division(flowers_budget,2)`

    >__[F&#58;variable_name&#58;variable_type&#58;variable_storage_type] request_type, URL, key__    
    (header) key:value   
    (body) string

    This is a fetched variable. Optobot supports fetching variables from a specified URL. In this case the request_type would be `GET` or `POST` based on the endpoint that you want to call. Optobot supports JSON or string response from the specified URL. In case of string response, key is not required. In case of JSOn response from the URL specified, the key format is `key1.key2.key3` in order to get nested keys from the response.   
     Example response `{key1: {key2: {key3: "value"}}}`   
    Example   
    [F:fetched_weather_var] GET, http://api.weatherstack.com/current?access_key=8da14f08dc9fe885d86c975fa1620d15&query={{location_var}}, current.temperature
    
     


6. __#Comment__
    A comment can be specified by adding __" # "__  at the beginning of a line. Any line that starts with __" # "__ is a comment and is completely ignored. 


* Run this command in the terminal on the root directory of optobot to create a new user, project and a new wit.ai app.    "project_name" and "email@example.com" should be substituted by the actual project name and user email. 

        $ bundle exec rake environment optobot:initial_create\["project_name","email@example.com"\]

    You will get a response like this :

        Initial_create task ...........
        Authentication data {"access-token"=>"Ge4PV2gkeG_5eHlkpTts-w", "token-type"=>"Bearer", "client"=>"stduHw5AeXOOinW3EYv-1w", "expiry"=>"2774771826", "uid"=>"11user_email@example.com"}
        project_id = 290
        wit_access_token = TMMHDH7GEWYZOPTWASAL2KCJ2HAXOPLJ

    Keep your Authentication data , project_id and wit_access_token as they will be used later. 

    Note that by running this command, a Wit.ai project is created that is owned by Optobot. To create a project owned by you, you need to create an account on Wit.ai. Follow the steps [here](/NLP_Engine) to get your server access token.    
    Open cloned optobot folder, open `.env` file and replace "WIT_SERVER_TOKEN" with your `Server Access Token`   

* Run this command after modifying `.optonlp` and `.optodsl` files to implement the conversation diagram using the DSL file and to train Wit on all used  expressions. This will train Wit on all `.optonlp` files and the conversations on all `.optodsl` files under the `train` folder in the project root. Note that each `.optodsl` will be considered as a different context unless the file name contains `no_context` string .

        $ bundle exec rake environment optobot:Train



### 3.2 Using a Ruby file
------------------

Using __my_first_project.rake file__ it will create a new user, project, contexts and dialogues. An example of a rake file for the same example discussed earlier is available on optobot repo in [“lib/tasks/my_first_project.rake”](https://github.com/Optomatica/optobot/blob/master/lib/tasks/my_first_project.rake)


* Run this command at project root to run the rake file `lib/tasks/my_first_project.rake`: 

        $ bundle exec rake environment example:MyFirstProject user_email=user@example.com project_name=my_first_project

    You will get a response like this :

        Authentication data {"access-token"=>"Ge4PV2gkeG_5eHlkpTts-w", "token-type"=>"Bearer", "client"=>"stduHw5AeXOOinW3EYv-1w", "expiry"=>"2774771826", "uid"=>"11user_email@example.com"}
        project_id = 290
        
    Keep your Authentication data and project_id as they will be used later. 


* Run this command to train Wit on all intents in file `train/wit_training.optonlp`: 

        $ bundle exec rake environment optobot:wit_train





4.Chatting
--------------

  To start chatting with OptoBot bot you created:  

* Run this command in the terminal to the start server:

      $ rails s   

* Run this command in another terminal window:

      $ bundle exec rake environment example:Chatting   



      
  If you say  __" Hi "__  , you will get a response like this :   
    __"Hi. How can I help you ? "__  


  If you reply with __"I want to buy flowers"__   
  you will get a response like this :
    __"Lovely! What is your budget?"__    
You can then respond by typing a number. To continue the conversation keep chatting with your bot.   

  If you want to stop chatting, just say __" end "__ and the chat will end. Note that "end" deletes all user's data and sessions. You can only use it in debug mode.







