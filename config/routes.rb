Rails.application.routes.draw do
  # Sidekiq web UI for monitoring background jobs
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # Authentication routes
  get "login", to: "sessions#new"
  get "test", to: "sessions#test"
  post "login", to: "sessions#create"  
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"
  
  # User management routes
  resources :users, except: [:destroy] do
    member do
      patch :deactivate
    end
  end

  # Set root path to dashboard
  root "dashboard#index"

  # Dashboard routes
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "dashboard/chart_data"
  
  # Debug route
  get "debug" => "debug#index"
  get "chart_debug" => "chart_debug#index"

  # Reports routes
  resources :reports, only: [:index] do
    collection do
      get :farm_summary
      get :cow_summary
      get :production_trends
      get :export
    end
  end

  # RESTful routes
  resources :farms do
    resources :cows do
      resources :production_records
      collection do
        get :chart_data
      end
    end
    resources :production_records
    resources :sales_records
  end

  # Standalone routes
  resources :cows do
    collection do
      get :search
      get :chart_data
    end
  end
  resources :production_records do
    collection do
      get :bulk_entry
      get :bulk_entry_fixed
      get :enhanced_bulk_entry
      post :bulk_update
      get :bulk_entry_stream  # SSE endpoint for real-time updates
    end
  end
  resources :sales_records

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
