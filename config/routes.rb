Rails.application.routes.draw do
  resources :data_summary, only: [:index]

  resources :versions, only: [:show, :index]
  special_characters    = ".-_".freeze
  allowed_characters    = "[A-Za-z0-9#{Regexp.escape(special_characters)}]+".freeze
  route_pattern          = /#{allowed_characters}/
  mount MaintenanceTasks::Engine => "/maintenance_tasks"
  resources :versions
  resources :blobs, param: :sha256 do
    member do
      get :raw
    end
  end
  resources :rubygems, param: :name, constraints: { id: route_pattern } do
    resource :file_history, only: [:show], param: :path, constraints: { id: /.+/} do
      get :diff
    end
  end
  resources :servers
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "servers#index"
end
