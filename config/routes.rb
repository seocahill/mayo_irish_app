Rails.application.routes.draw do
  root "lessons#index"
  resources :lessons, only: [:index, :show, :edit, :update]
  get "up" => "rails/health#show", as: :rails_health_check
end
