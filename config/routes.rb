Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Public: customers submit support requests here (no login required).
  get  "support",        to: "support_requests#new",    as: :new_support_request
  post "support",        to: "support_requests#create", as: :support_requests
  get  "support/thanks/:reference", to: "support_requests#thanks", as: :support_thanks

  # Agent workspace (authentication required).
  resources :tickets, only: %i[index show] do
    member do
      patch :assign
      patch :status
    end
    resources :comments, only: :create
  end

  # Health check for load balancers / Render.
  get "up" => "rails/health#show", as: :rails_health_check

  # Agents land on the ticket queue; unauthenticated visitors are sent to login.
  root "tickets#index"
end
