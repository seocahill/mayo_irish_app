Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  get "pending", to: "registrations#pending", as: :pending_approval
  resources :passwords, param: :token, only: %i[new create edit update]

  root "lessons#index"
  resources :lessons, only: [:index, :new, :create, :show, :edit, :update] do
    resources :grammar_rules, only: [:edit, :update], shallow: true
    resources :grammar_sections, only: [:edit, :update], shallow: true
    resources :text_passages, only: [:edit, :update], shallow: true
    resources :exercises, only: [:edit, :update], shallow: true
    resources :lesson_blocks, only: [:create, :edit, :update, :destroy], shallow: true do
      post :reorder, on: :collection
    end
    resource :chat, only: [:show], controller: "lesson_chat" do
      post :message,  on: :member
      delete :clear,  on: :member
    end
    resource :quiz, only: [:show], controller: "quizzes" do
      post   :answer, on: :member
      delete :reset,  on: :member
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
