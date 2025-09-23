Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
# Defines the root path route ("/")
# root "posts#index"
  devise_for :users,
             defaults: { format: :json },
             controllers: {
               sessions:      "users/sessions",
               registrations: "users/registrations" # optional, if you added it
             }
  # API
  namespace :api do
    namespace :v1 do
      resources :people, only: [:index, :show, :create, :update, :destroy]
      resources :documents, only: [:index, :show, :create, :update, :destroy]
      resources :contracts do
        resources :reminders
        resources :expenses
      end
    end
  end
end
