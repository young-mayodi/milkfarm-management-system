Rails.application.routes.draw do
  # API routes for mobile app
  namespace :api do
    post "login", to: "auth#login"
    post "logout", to: "auth#logout"
    get "user", to: "auth#user"

    resources :farms, only: [ :index, :show ]
    resources :cows, only: [ :index, :show, :create, :update ]
    resources :production_records, only: [ :index, :show, :create, :update ]
    resources :reports, only: [ :index, :show ]

    # Dashboard endpoint
    get "dashboard", to: "dashboard#index"
  end

  # Health check and monitoring routes
  get "health", to: "health#index"
  get "health/bugsnag_test", to: "health#bugsnag_test"

  # Financial Reports routes
  resources :financial_reports, only: [ :index ] do
    collection do
      get :profit_loss
      get :cost_analysis
      get :roi_report
    end
  end

  get "animal_management/dashboard"
  get "animal_management/health_overview"
  get "animal_management/breeding_overview"
  get "animal_management/vaccination_overview"

  # Alerts system routes
  resources :alerts, only: [ :index ] do
    collection do
      get :dashboard_summary
    end
    member do
      post :mark_as_read
    end
  end

  # Sidekiq web UI for monitoring background jobs (optional - requires sidekiq gem)
  if defined?(Sidekiq)
    begin
      require "sidekiq/web"
      mount Sidekiq::Web => "/sidekiq"
    rescue LoadError
      # Sidekiq not available
    end
  end

  # Authentication routes
  get "login", to: "sessions#new"
  get "test", to: "sessions#test"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"

  # User management routes
  resources :users, except: [ :destroy ] do
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
  resources :reports, only: [ :index ] do
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
      # Advanced Animal Management Routes
      resources :health_records
      resources :breeding_records
      resources :vaccination_records
      # Note: graduate_to_dairy, mark_as_sold, mark_as_deceased, reactivate, lineage
      # are defined in standalone cows routes below for cleaner URLs
      collection do
        get :chart_data
      end
    end
    resources :production_records
    resources :sales_records
    resources :animal_sales
  end

  # Standalone routes for cow actions
  resources :cows do
    member do
      patch :graduate_to_dairy
      patch :mark_as_sold
      patch :mark_as_deceased
      patch :reactivate
      get :lineage, to: "lineage#show"
    end
    collection do
      get :search
      get :chart_data
    end
  end

  # Calves routes - separate from cows for better organization
  resources :calves do
    collection do
      get :chart_data
    end
    member do
      get :growth_chart
    end
  end

  resources :production_records do
    collection do
      get :bulk_entry
      get :enhanced_bulk_entry
      post :bulk_update
      post :save_draft  # Auto-save draft endpoint
      get :bulk_entry_stream  # SSE endpoint for real-time updates
      get :production_time_reports  # Production time reports
      get :production_trends  # Detailed production trends by cow and period
    end
  end
  resources :sales_records
  resources :animal_sales

  # Advanced Animal Management - Standalone routes
  resources :health_records do
    collection do
      get :dashboard
      get :alerts
    end
  end

  resources :breeding_records do
    collection do
      get :dashboard
      get :calendar
      get :due_soon
    end
  end

  resources :vaccination_records do
    collection do
      get :dashboard
      get :schedule
      get :overdue
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Error routes for custom error pages
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
