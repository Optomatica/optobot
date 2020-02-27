
# __System components__ 
 Read below the description of the system components that will help you understand Optobot's structure:   

__PROJECTS:__ 

Any user can create multiple Chatbot projects. A project contains all the dialogues(nodes), logic and the responses the bot can say. 

The __Project Owner__ can give the project;
 - A name, 
 - Add a Wit.ai server token.
 - Add an external backend URL 
 - Connect it to their page on Facebook. 

__USERS:__

For every project, the user can have one role from the following:   

* __Admin__: The project creator, has full access over the project.
* __Author__: Can create, edit, delete dialogues, but can’t delete projects or add other authors.
* __Subscriber__: Can only chat with the bot.


__CONTEXTS:__   
The context is a conceptual categorization for the dialogues. It marks dialogues that are related to the same topic.
If you have multiple trees of dialogues, each tree belongs to a certain context. See example below.   

![Context example](/assets/images/context_example.png)


__DIALOGUES/NODES:__

A dialogue is the main component that declares how the conversation should flow. It can have one or more variables that have responses to be said by the bot. Depending on the user's reply and some conditions, Optobot will move to one of the *Children* dialogues.   
A leaf dialogue node doesn't have variables. It has responses that are not waiting for the user's reply. A dialogue may have a Wit.ai intent that allows Optobot to go to this node directly without passing through the *Parent* nodes first.

__VARIABLES (REQUIREMENTS):__ 

A variable is a requirement that needs to be obtained to be able to fulfill the conditions on the arcs for Optobot to decide which dialogue to go to.     

Optobot can obtain the data through one of the following:   
1. Collected: The variable must have a response (said by the bot) and may have options. The data is obtained from the user's reply. If variable has options, the author can restrict the user not to write for simplicity in understanding.
2. Provided: The data can be found in the user data table.
3. Fetched: From an API end-point.


__RESPONSES:__

The response which the bot should say to the user. The response content can be text, image or video.   


__OPTIONS:__  

The options are quick replies that the bot gives the user to select from. A condition can be set on the option value so the user can choose one of the options, and accordingly, Optobot can decide which dialogue to go to.

__PARAMETERS:__ 

Parameters can have a value or a range to be compared with the condition's variable data.   


__CONDITIONS:__ 

There is an **arc** connecting a *parent* dialogue node and its *child* node. The arc can have one or more conditions that all must be fulfilled for Optobot to move to this child node.   

A condition is set on a specific variable that needs to compare the data stored for it with the value of the parameter or the option. 
