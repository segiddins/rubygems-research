# == Route Map
#
# I, [2024-04-15T17:42:55.336961 #60969]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - PROFILING - {"profiling_enabled":false}
# I, [2024-04-15T17:42:55.337167 #60969]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - CORE - {"date":"2024-04-15T17:42:55-07:00","os_name":"arm64-apple-darwin23","version":"1.20.0","lang":"ruby","lang_version":"3.3.0","env":null,"service":"rake","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.0","health_metrics_enabled":false}
# I, [2024-04-15T17:42:56.205863 #61003]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - PROFILING - {"profiling_enabled":false}
# I, [2024-04-15T17:42:56.206061 #61003]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - CORE - {"date":"2024-04-15T17:42:56-07:00","os_name":"arm64-apple-darwin23","version":"1.20.0","lang":"ruby","lang_version":"3.3.0","env":null,"service":"rails","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.0","health_metrics_enabled":false}
#                            Prefix Verb URI Pattern                                         Controller#Action
#             version_import_errors GET  /version_import_errors(.:format)                    version_import_errors#index
#                data_summary_index GET  /data_summary(.:format)                             data_summary#index
#                          versions GET  /versions(.:format)                                 versions#index
#                           version GET  /versions/:id(.:format)                             versions#show
#                          raw_blob GET  /blobs/:sha256/raw(.:format)                        blobs#raw
#                             blobs GET  /blobs(.:format)                                    blobs#index
#                              blob GET  /blobs/:sha256(.:format)                            blobs#show
#                      diff_rubygem GET  /rubygems/:name/diff(.:format)                      rubygems#diff
#         diff_rubygem_file_history GET  /rubygems/:rubygem_name/file_history/diff(.:format) file_histories#diff
#              rubygem_file_history GET  /rubygems/:rubygem_name/file_history(.:format)      file_histories#show
#                          rubygems GET  /rubygems(.:format)                                 rubygems#index
#                           rubygem GET  /rubygems/:name(.:format)                           rubygems#show
#                           servers GET  /servers(.:format)                                  servers#index
#                            server GET  /servers/:id(.:format)                              servers#show
#                rails_health_check GET  /up(.:format)                                       rails/health#show
#                              root GET  /                                                   servers#index
#                 maintenance_tasks      /maintenance_tasks                                  MaintenanceTasks::Engine
#  turbo_recede_historical_location GET  /recede_historical_location(.:format)               turbo/native/navigation#recede
#  turbo_resume_historical_location GET  /resume_historical_location(.:format)               turbo/native/navigation#resume
# turbo_refresh_historical_location GET  /refresh_historical_location(.:format)              turbo/native/navigation#refresh
#
# Routes for MaintenanceTasks::Engine:
#  pause_task_run PUT  /tasks/:task_id/runs/:id/pause  maintenance_tasks/runs#pause
# cancel_task_run PUT  /tasks/:task_id/runs/:id/cancel maintenance_tasks/runs#cancel
# resume_task_run PUT  /tasks/:task_id/runs/:id/resume maintenance_tasks/runs#resume
#       task_runs POST /tasks/:task_id/runs            maintenance_tasks/runs#create
#           tasks GET  /tasks                          maintenance_tasks/tasks#index
#            task GET  /tasks/:id                      maintenance_tasks/tasks#show
#            root GET  /                               maintenance_tasks/tasks#index

Rails.application.routes.draw do
  resources :version_import_errors, only: [:index]
  resources :data_summary, only: [:index]

  resources :versions, only: [:show, :index]
  special_characters    = ".-_".freeze
  allowed_characters    = "[A-Za-z0-9#{Regexp.escape(special_characters)}]+".freeze
  route_pattern          = /#{allowed_characters}/

  resources :blobs, only: %i[show index], param: :sha256 do
    member do
      get :raw
    end
  end
  resources :rubygems, only: %i[show index], param: :name, constraints: { id: route_pattern } do
    get :diff, on: :member
    resource :file_history, only: [:show], param: :path, constraints: { id: /.+/} do
      get :diff
    end
  end
  resources :servers, only: %i[show index]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "servers#index"

  constraints ->(request) { request.local? || request.remote_ip == "100.86.251.32" } do
    mount MaintenanceTasks::Engine => "/maintenance_tasks"
  end
end
