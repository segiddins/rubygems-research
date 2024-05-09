# == Route Map
#
# I, [2024-04-16T16:46:29.414476 #83800]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - PROFILING - {"profiling_enabled":false}
# I, [2024-04-16T16:46:29.414653 #83800]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - CORE - {"date":"2024-04-16T16:46:29-07:00","os_name":"arm64-apple-darwin23","version":"1.20.0","lang":"ruby","lang_version":"3.3.0","env":null,"service":"rake","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.0","health_metrics_enabled":false}
# I, [2024-04-16T16:46:30.325963 #83815]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - PROFILING - {"profiling_enabled":false}
# I, [2024-04-16T16:46:30.326156 #83815]  INFO -- ddtrace: [ddtrace] DATADOG CONFIGURATION - CORE - {"date":"2024-04-16T16:46:30-07:00","os_name":"arm64-apple-darwin23","version":"1.20.0","lang":"ruby","lang_version":"3.3.0","env":null,"service":"rails","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.0","health_metrics_enabled":false}
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
#                          good_job      /good_job                                           GoodJob::Engine
#                 maintenance_tasks      /maintenance_tasks                                  MaintenanceTasks::Engine
#                           pg_hero      /pghero                                             PgHero::Engine
#  turbo_recede_historical_location GET  /recede_historical_location(.:format)               turbo/native/navigation#recede
#  turbo_resume_historical_location GET  /resume_historical_location(.:format)               turbo/native/navigation#resume
# turbo_refresh_historical_location GET  /refresh_historical_location(.:format)              turbo/native/navigation#refresh
#
# Routes for GoodJob::Engine:
#                root GET    /                                         redirect(301, path: jobs)
#    mass_update_jobs GET    /jobs/mass_update(.:format)               redirect(301, path: jobs)
#                     PUT    /jobs/mass_update(.:format)               good_job/jobs#mass_update
#         discard_job PUT    /jobs/:id/discard(.:format)               good_job/jobs#discard
#   force_discard_job PUT    /jobs/:id/force_discard(.:format)         good_job/jobs#force_discard
#      reschedule_job PUT    /jobs/:id/reschedule(.:format)            good_job/jobs#reschedule
#           retry_job PUT    /jobs/:id/retry(.:format)                 good_job/jobs#retry
#                jobs GET    /jobs(.:format)                           good_job/jobs#index
#                 job GET    /jobs/:id(.:format)                       good_job/jobs#show
#                     DELETE /jobs/:id(.:format)                       good_job/jobs#destroy
# metrics_primary_nav GET    /jobs/metrics/primary_nav(.:format)       good_job/metrics#primary_nav
#  metrics_job_status GET    /jobs/metrics/job_status(.:format)        good_job/metrics#job_status
#             batches GET    /batches(.:format)                        good_job/batches#index
#               batch GET    /batches/:id(.:format)                    good_job/batches#show
#  enqueue_cron_entry POST   /cron_entries/:cron_key/enqueue(.:format) good_job/cron_entries#enqueue
#   enable_cron_entry PUT    /cron_entries/:cron_key/enable(.:format)  good_job/cron_entries#enable
#  disable_cron_entry PUT    /cron_entries/:cron_key/disable(.:format) good_job/cron_entries#disable
#        cron_entries GET    /cron_entries(.:format)                   good_job/cron_entries#index
#          cron_entry GET    /cron_entries/:cron_key(.:format)         good_job/cron_entries#show
#           processes GET    /processes(.:format)                      good_job/processes#index
#     frontend_module GET    /frontend/modules/:name(.:format)         good_job/frontends#module {:format=>"js"}
#     frontend_static GET    /frontend/static/:name(.:format)          good_job/frontends#static {:format=>["css", "js"]}
#
# Routes for MaintenanceTasks::Engine:
#  pause_task_run PUT  /tasks/:task_id/runs/:id/pause  maintenance_tasks/runs#pause
# cancel_task_run PUT  /tasks/:task_id/runs/:id/cancel maintenance_tasks/runs#cancel
# resume_task_run PUT  /tasks/:task_id/runs/:id/resume maintenance_tasks/runs#resume
#       task_runs POST /tasks/:task_id/runs            maintenance_tasks/runs#create
#           tasks GET  /tasks                          maintenance_tasks/tasks#index
#            task GET  /tasks/:id                      maintenance_tasks/tasks#show
#            root GET  /                               maintenance_tasks/tasks#index
#
# Routes for PgHero::Engine:
#                     space GET  (/:database)/space(.:format)                     pg_hero/home#space
#            relation_space GET  (/:database)/space/:relation(.:format)           pg_hero/home#relation_space
#               index_bloat GET  (/:database)/index_bloat(.:format)               pg_hero/home#index_bloat
#              live_queries GET  (/:database)/live_queries(.:format)              pg_hero/home#live_queries
#                   queries GET  (/:database)/queries(.:format)                   pg_hero/home#queries
#                show_query GET  (/:database)/queries/:query_hash(.:format)       pg_hero/home#show_query
#                    system GET  (/:database)/system(.:format)                    pg_hero/home#system
#                 cpu_usage GET  (/:database)/cpu_usage(.:format)                 pg_hero/home#cpu_usage
#          connection_stats GET  (/:database)/connection_stats(.:format)          pg_hero/home#connection_stats
#     replication_lag_stats GET  (/:database)/replication_lag_stats(.:format)     pg_hero/home#replication_lag_stats
#                load_stats GET  (/:database)/load_stats(.:format)                pg_hero/home#load_stats
#          free_space_stats GET  (/:database)/free_space_stats(.:format)          pg_hero/home#free_space_stats
#                   explain GET  (/:database)/explain(.:format)                   pg_hero/home#explain
#                      tune GET  (/:database)/tune(.:format)                      pg_hero/home#tune
#               connections GET  (/:database)/connections(.:format)               pg_hero/home#connections
#               maintenance GET  (/:database)/maintenance(.:format)               pg_hero/home#maintenance
#                      kill POST (/:database)/kill(.:format)                      pg_hero/home#kill
# kill_long_running_queries POST (/:database)/kill_long_running_queries(.:format) pg_hero/home#kill_long_running_queries
#                  kill_all POST (/:database)/kill_all(.:format)                  pg_hero/home#kill_all
#        enable_query_stats POST (/:database)/enable_query_stats(.:format)        pg_hero/home#enable_query_stats
#                           POST (/:database)/explain(.:format)                   pg_hero/home#explain
#         reset_query_stats POST (/:database)/reset_query_stats(.:format)         pg_hero/home#reset_query_stats
#              system_stats GET  (/:database)/system_stats(.:format)              redirect(301, system)
#               query_stats GET  (/:database)/query_stats(.:format)               redirect(301, queries)
#                      root GET  /(:database)(.:format)                           pg_hero/home#index

Rails.application.routes.draw do
  resources :gem_downloads
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
    mount GoodJob::Engine, at: '/good_job'
    mount MaintenanceTasks::Engine, at: "/maintenance_tasks"
    mount PgHero::Engine, at: "/pghero"
  end
end
