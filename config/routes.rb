Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount_devise_token_auth_for 'User', at: 'auth'
  apipie
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/__webpack_hmr', :to => redirect('/index.html')
  get '*.map', :to => redirect('/index.html')

  concern :c_v_responses do
    resources :responses do
      get 'show', to: 'responses#show_for_option_of_variable' ,on: :member
      post 'create', to: 'responses#create_for_option_of_variable', on: :collection
      delete 'destroy', to: 'responses#destroy_for_option_of_variable', on: :member #as default
      resources :response_contents do
        post 'create', to: 'response_contents#create_for_variable', on: :collection
        put 'update', to: 'response_contents#update_for_variable', on: :member
        delete 'destroy', to: 'response_contents#destroy_for_variable', on: :member #as default
      end
    end
  end

  concern :c_options do
    resources :options, concerns: :c_v_responses do
      get 'list' ,on: :collection
      post 'create', on: :collection
      put 'update', on: :member
      delete 'destroy', on: :member #as default
    end
  end

  concern :c_variables do
    resources :variables, concerns: :c_options do
      get 'list' ,on: :collection
      get 'show' ,on: :member
      post 'create' ,on: :collection
      put 'update', on: :member
      delete 'destroy', on: :member
      resources :responses do
          get 'show', to: 'responses#show_for_variable' ,on: :member
          post 'create', to: 'responses#create_for_variable', on: :collection
          put 'reorder', to: 'responses#reorder_for_variable', on: :collection
          delete 'destroy', to: 'responses#destroy_for_variable', on: :member #as default
          resources :response_contents do
            post 'create', to: 'response_contents#create_for_variable', on: :collection
            put 'update', to: 'response_contents#update_for_variable', on: :member
            delete 'destroy', to: 'response_contents#destroy_for_variable', on: :member #as default
          end
        end
    end
  end

  resources :users do

    member do
      get 'show'
    end

    resources :projects do
      post 'create' ,on: :collection
      get 'list',on: :collection

      member do
        get 'show'
        put 'update'
        delete 'destroy'
        post 'add_users_to_project'
        post 'remove_users_from_project'
        get 'list_project_users'
        post 'set_facebook_access_token'
        get 'enable_get_started'
      end
    end
    get 'webhook', action: 'vwebhook', on: :collection
    post 'webhook', to: 'chatbot#webhook', on: :collection

  end


  resources :projects, concerns: :c_variables do
    member do
      post 'chatbot', to: 'chatbot#chat'
      post 'send_message_to_user', to: 'chatbot#send_message_to_user'
      post 'linkFacebook', to: 'chatbot#linkFacebook'
      post 'go_to_session', to: 'chatbot#go_to_session'
      post 'get_chat_messages'
      get 'get_chat_problems'
      delete 'remove_problem'
      post 'update_session'
      get 'export_dialogues_data'
      post 'import_dialogues_data'
      post 'import_context_dialogues_data'
      post 'train_wit'
      get 'release'
      get 'initial_node', to: 'chatbot#start_chating'
    end

    resources :user_data do
      post 'list' ,on: :collection
      post 'create' ,on: :collection
      put 'update', on: :member
      delete 'destroy', on: :member
    end
  end
  # in project
  resources :arcs do
    get 'show' ,on: :member #conditions
    get 'list_variables' ,on: :member
    resources :parameters do
      # get 'list' ,on: :collection
      post 'create' ,on: :collection
      put 'update', on: :member
      delete 'destroy', on: :member #as default
    end
  end
  delete '/conditions/:condition_id/options/:id/remove_from_condition', to: 'options#remove_from_condition'
  post '/arcs/:arc_id/options/:id/add_to_condition', to: 'options#add_to_condition'
  resources :dialogues, concerns: :c_variables do
    post 'list' ,on: :collection
    post 'create' ,on: :collection
    get 'show' ,on: :member
    put 'update', on: :member
    post 'add_root_parent', on: :member
    delete 'destroy', on: :member #as default
    resources :responses do
      get 'show', to: 'responses#show_for_dialogue' ,on: :member
      post 'create', to: 'responses#create_for_dialogue', on: :collection
      put 'reorder', to: 'responses#reorder_for_dialogue', on: :collection
      delete 'destroy', to: 'responses#destroy_for_dialogue', on: :member #as default
      resources :response_contents do
        post 'create', to: 'response_contents#create_for_dialogue', on: :collection
        put 'update', to: 'response_contents#update_for_dialogue', on: :member
        delete 'destroy', to: 'response_contents#destroy_for_dialogue', on: :member #as default
      end
    end
  end
  resources :contexts do
    get '/has_dialogues', to: 'contexts#get_dialogues_of_context', on: :member
    get 'list' ,on: :collection
    post 'create' ,on: :collection
    get 'show', on: :member
    put 'update', on: :member
    delete 'destroy', on: :member
  end
end
