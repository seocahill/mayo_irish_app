Rails.application.routes.draw do
  use_doorkeeper

  # claude.ai MCP connector: OAuth 2.1 discovery, dynamic client registration,
  # and the MCP endpoint itself.
  get ".well-known/oauth-authorization-server", to: "oauth/metadata#authorization_server"
  get ".well-known/oauth-authorization-server/mcp", to: "oauth/metadata#authorization_server"
  get ".well-known/oauth-protected-resource", to: "oauth/metadata#protected_resource", as: :oauth_protected_resource
  get ".well-known/oauth-protected-resource/mcp", to: "oauth/metadata#protected_resource"
  post "oauth/register", to: "oauth/registrations#create", as: :oauth_register
  match "mcp", to: "mcp#invoke", via: %i[get post], as: :mcp

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  get "pending", to: "registrations#pending", as: :pending_approval
  resources :passwords, param: :token, only: %i[new create edit update]

  root "home#show"
  resource :onboarding, only: %i[new create]
  get "search", to: "search#index", as: :search
  resources :vocabulary_items, only: [] do
    resource :pronunciation, only: :show
  end
  resources :chat_messages, only: [] do
    resource :pronunciation, only: :show, controller: "chat_message_pronunciations"
    resource :flag, only: :create, controller: "chat_message_flags"
  end
  resources :flagged_replies, only: %i[index destroy]
  resources :lessons, only: [:index, :new, :create, :show, :edit, :update] do
    resource :review, only: %i[create destroy], controller: "lesson_reviews"
    resources :versions, only: :index do
      resource :undo, only: :create, controller: "version_undos"
    end
    resources :grammar_rules, only: [:edit, :update], shallow: true
    resources :grammar_sections, only: [:edit, :update], shallow: true
    resources :lesson_blocks, only: [:create, :edit, :update, :destroy], shallow: true do
      post :reorder, on: :collection
    end
    resource :chat, only: [:show], controller: "lesson_chat" do
      post :message,  on: :member
      delete :clear,  on: :member
    end
    resource :conversation, only: %i[show destroy], controller: "lesson_conversations" do
      post :message, on: :member
    end
    resource :quiz, only: [:show], controller: "quizzes" do
      post   :answer, on: :member
      delete :reset,  on: :member
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
