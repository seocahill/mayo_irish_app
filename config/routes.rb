Rails.application.routes.draw do
  root "lessons#index"
  resources :lessons, only: [:index, :show, :edit, :update] do
    resources :grammar_rules, only: [:edit, :update], shallow: true
    resources :grammar_sections, only: [:edit, :update], shallow: true
    resources :text_passages, only: [:edit, :update], shallow: true
    resources :exercises, only: [:edit, :update], shallow: true
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
