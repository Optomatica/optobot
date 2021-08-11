# __Detailed Overview__ 

### Dialogues:

- Non terminal nodes must have variables,  
- Non root nodes must have conditions,  
- Each node can have [0-n] responses which all the bot should say to the user,  
- Dialogue should have variables if it is not a terminal node,  
- Dialogue has no options, but the variable can have.

1. Arcs:  
    The conditions of the arc must be matched for Optobot to go to the arc tail.   
    Conditions must be linked to a variable.  
    The condition should either have one parameter, be pointing on one option, or include both.

    A parameter has a specific value or a range. The user's reply should match the value or be in the range inorder for the condition to be fulfilled.  
2. Intent:  
    Root node must have an intent, so Optobot can go to this node when user says this intent.

### Variables

* Types:

    1. Collected - by chatting with the user. It must have response(s) and could have options for simplicity.
      - Option
      - Free text
    2. Provided; means the bot can find it in user_data table and its source doesn’t matter.
    3. Fetched - from an API end-point.
:normal, :timeseries,  , :timeseries_in_cache

* Persistence (Storage type)
    1. In cache - Saved temporarily to get the remaining required variables and removed once all requirements (variables) gathered and used for deciding the next dialogue node.
    2. In session - Saved temporarily to be used in some node in the current dialogue path and removed once reaching a terminal node.
    3. For some period (once/normal) - The author should set a validity period, to ensure an end date. If no date is set the data will be valid indefinitely.
    4. Time series - Have a validity period. After they expire, the user will be asked the variable response again, a new value will be appended.  
    5. Time series in cache - Saved temporarily to get the remaining required variables and expire once all requirements (variables) gathered. After they expire, the user will be asked the variable response again, a new value will be appended.  

* Options

  A variable can have many options.  
  One option has one response.

### Responses

  Each response can have a variety of response content, which can be chosen by the bot randomly.

  __Response_content__

  Can be a text, image and video.


### Predefined methods

1. __sum__   
  __sum(var_name,var_name,...)__   
  It can add 2 numbers or more, replace var_name with a variable name or a constant value   
  Example: `sum(1,2,3)`   
  Result: 6

1. __subtract__   
  __subtract(first_var_name,second_var_name)__   
  It subtracts second variable from the first variable, replace var_name with a variable name or a constant value
  Example: `subtract(10,5)`   
  Result: 5

1. __multiply__   
  __multiply(var_name,var_name,...)__   
  It can multiply 2 numbers or more, replace var_name with a variable name or a constant value   
  Example: `multiply(1,2,3)`   
  Result: 6

1. __division__   
  __division,first_var_name,second_var_name__   
  The first variable is divided by the second variable, replace var_name with a variable name or a constant value   
  Example: `division(5,2)`   
  Result: 2.5

1. __int_division__   
  __int_division(first_var_name,second_var_name)__   
  The first variable is divided by the second variable and the result will always be int(floor division), replace var_name with a variable name or a constant value   
  Example: `int_division(5,2)`   
  Result: 2


1. __power__     
  __power(first_var_name,second_var_name)__   
  The first variable to the power of second variable, replace var_name with a variable name or a constant value   
  Example: `power(10,3)`   
  Result: 1000

1. __weather__   
  __weather(city_name)__   
  It returns the temperature in celsius at this city   
  Example: `weather(paris)` 



### Chatbot logic flow

__When__ the user interacts/chats with Optobot for the first time (No user session)  -> Go to onboarding context `go_to_onboarding`

__Once__
__The context, dialogue and variable are set [means Optobot has asked for variable X]__

1. User replies on this variable X  → satisfies variable X → go to check process
2. User replies on this variable (satisfied) and another expected variable(s) Y
1. Entity of variable y is unique - confirmation
2. Entity of variable y is not unique - confirmation variable Y and Z , etc
3. User reply on this variable (satisfied) and another unexpected variable(s) → ignore other variables → go to check process
4. User reply but doesn’t satisfy X
1. Intent: → go to New intent process
2. Not intent:  Ask for this variable again

 __I have context and no dialogue__

1. Intent: → go to new intent process
2. not intent:  Fallback (I don’t understand)

  __I have no context__

1. Intent: → go to New intent process B
2. not intent: Fallback (I don’t understand)


  __Check process: (go_to_next_dialogue)__

if conditions of any child arc is satisfied:
1. Yes
    Next dialogue (choose the one with max number of conditions, else random)
    Check if it is terminal node, reset dialogue id and variable id in session

2. No
1. check if there is missing variable
    * collected variable → ask for this variable
    * provided/ fetched → Fallback (technical problem)
2. Fallback (no route matching) and send notification to author


  __New intent process: If user give me new intent__

1. search in root dialogues in current context with current user intent (intent collected from last user statement),  (choose the one with max number of conditions)

2. search in other contexts root dialogues intents
  if number of roots matched > 1 and in different contexts, say fallback ( Do you mean .. or .. )
  else: (choose the one with max number of conditions) and reset session

3. search in knowledge base (quick replies: context_id = null and has intent)

4. Fallback (I don’t understand)



