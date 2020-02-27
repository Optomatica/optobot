
# __User Guide__

This is a guide on how to build your own chatbot with **OptoBot**. Follow these simple steps and you will be up and running in no time.

Options:  
:: As a User you can create multiple projects,  
:: Each project may include one or more context,  
:: Each context may include one or more dialogue.  

When the user is chatting with the bot:   

   User's text/words are sent to Wit.ai (NLU engine api) which in return replies with the intent of these words. 
   Optobot uses this intent to decide which dialogue it should display, comparing each dialogue's intent with Wit's reply.

There are two types of dialogues:

   * Dialogue without Children
   * Dialogue with Children

__*Dialogue without Children__  
If the dialogue has No Children (No Variables), Optobot will display the response of the dialogue.

__*Dialogue with Children__  
If the dialogue has children (has Variables), Optobot will display the response of the variables and the user reply will be saved in the user data for this variable/ these variables.   

Afterwards Optobot will choose one of the dialogue's children to redirect the user to it based on the conditions.  
Each child has an arc which has a condition.
depending on which condition is fulfilled , OptoBot will redirect the user to that dialogue.  

The below diagram shows an example of a project that has 1 context with 10 dialogues/nodes.  
The first node has an **intent value = "flowers"**   
When the user starts chatting by saying "I want to buy flowers". The words are sent to Wit.ai NLU and OptoBot receives the intent **"flowers"**  (assuming that you have trained Wit.ai).   

Optobot enters Node#1 and replies to the user with "Lovely! What is your budget?"   
If the users says "6", hence fulfilling the condition on Arc#1. Optobot will move to Node#2 and reply with two responses, the first one is text and the second one is image. However, if the user says "75", hence fulfilling the condition on the Arc#3 and reply with Variable 4 response and give the users options to choose from and so on.    


![Diagram Flower ](/assets/images/buy_flowers.jpg)
![Diagram Flower chatting ](/assets/images/buy_flowers_chatting.png)

