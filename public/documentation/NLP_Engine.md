
# __NLP Engine__

OptoBot is currently using wit.ai as its default NLU engine.  

OptoBot has specified a standard for the params and responses expected  for actionable data (text or voice which are supported by wit.ai). If a user does not wish to use wit.ai for NLU and chooses to use:

   * Dialogue flow
   * Watson
   * Any other NLU engine including custom built ones

They can do so, by adhering to the standards put forth by Optobot and mapping the responses received from those engines, to the standard.  

__Note:__ If the user does not wish to use any NLU engine, s/he will need to disable free text.


### __Train your NLU engine__

The instructions provided here are for training the wit.ai NLU engine. If the user is using any other NLU engine, they need to follow the instructions provided by its developers. 

1. Sign up to wit.ai using a GitHub or Facebook account:

    Go to [Wit.ai home page](https://wit.ai/) and sign in with your GitHub or Facebook account.

2. Create a wit.ai app:
    * In the top right corner of the screen, press the ‘+’ symbol to create a new app. 
    * Enter the name of the app
    * Write down a description for the app (Optional step) 
    * Choose whether you want it to be open/public (your app will be open to the community ) or private (your app will be private and accessible only to you and the developers you decide to share your app with.)
    * Click the "Create App" button 

    ![Wit.ai ](/assets/images/wit_images/wit_1.png)

#### __Training Wit through its web based user interface:__

__Define your first entity:__   

An entity in wit.ai is the basic unit of information. The aim of developer training wit.ai, is to allow Wit to extract entities that are relevant to the application they are building, from the text that users have entered in their app. 
The first screen that appears after the creation of an application, is the ‘understanding’ screen, that allows developers to add new entities of various types (intent, location, sentiment, date, ect) depending on the application they are building. Intent is one of the most important entities that a developer needs to define, as it captures what the user wants done.  


Assuming for example, that the user of an app enters the following text:
‘What is the temperature in Paris now?’ 
The developer would want the NLU component of their chatbot to capture the intent behind this statement which can be something like ‘getTemprature’ as well as the location, which is ‘Paris’. To do this the developer has to train the NLU component to do so by entering various text snippets are represent examples of the ‘getTempreture’ intent.


![Wit Training 1 ](/assets/images/wit_images/image1.png)   

The next time you enter a similar piece of text, Wit will be able to automatically detect the intent   
![Wit Training 2 ](/assets/images/wit_images/image2.png)

Now you can highlight the city in the text (London in the figure above) and define a location entity for it:   
![Wit Training 3 ](/assets/images/wit_images/image3.png)

The next time you enter a different city, Wit will recognize it as shown below:   
![Wit Training 4 ](/assets/images/wit_images/image4.png)   

Wit.ai has many built in entities, for recognizing all sorts of data such as greetings, sentiment, locations, etc. Whenever possible, use Wit’s built in entities as this will save you training time. More documentation can be found on the wit.ai web site.   


__Training Wit using curl:__   
You can train Wit using calls such as the one shown below:    


            curl -X POST 'https://api.wit.ai/samples?v=20170307' \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '[{
                    "text": "hi",
                    "entities": [
                    {
                        "entity": "intent",
                        "value": "Greeting"
                    }
                    ]
                }]'

To do so:
1. Login to Wit.ai and open the application you want to train. 
2. Press the settings option, which can be found at the top right corner of the screen.
3. Copy the app token (Server Access Token) as highlighted in the figure below, and replace the term $TOKEN in the above call, with its value.  

![Wit Training 5 ](/assets/images/wit_images/image5.png)   

The different fields in the call can be described as follows:   
        * Text: The sentence you want it.ai to understand.    
        * Intent: Trait entity.    
        * Value: The name of the intent.    



4. Query your app  
    You can query your app via the Wit.ai API using this curl command  
    Example: Test the intent of this sentence "hello". Don't forget to replace the $TOKEN with your token   

            curl \
            -H 'Authorization: Bearer NZ3FCS4UXPXPG7VI7XE2YZI5DXOXIEOI' \
            'https://api.wit.ai/message?v=20190617&q=hello'

    You will get back a result similar to this:

            {
            "msg_id":"1Bq1U97VwhMIfGLWF",
            "_text":"hello",
            "entities" : {
                "greetings" : [ {
                "confidence" : 0.99988770484656,
                "value" : "true"
                } ]
            }
            }




__Training Wit using the OptoBot api:__  

Yet, Another way to train Wit.ai is by using __Optobot__ api to train Wit.ai on multiple expressions in one go.  
[this example file of wit training ](https://github.com/Optomatica/optobot/blob/master/train/wit_training.optonlp)  

__[I:intent_name]__ This syntax represents a declaration of an intent, followed by examples for this intent. Each example should be in a line.   
__[E:wit$enitity_name]__ This syntax represents a declaration of an entity, followed by examples for this entity.
Wit.ai has Built-in Entities, you can check them [here ](https://wit.ai/docs/built-in-entities/20180601)    



* Using this endpoint: __" http://localhost:3000/projects/1/train_wit "__  
Don't forget to assign the parameters __"file" and "language"__    
or you can just use this command 

        $ bundle exec rake environment optobot:wit_train






