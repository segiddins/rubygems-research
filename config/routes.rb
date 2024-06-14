# == Route Map
#
# I, [2024-06-14T12:26:24.505147 #9738]  INFO -- datadog: [datadog] DATADOG CONFIGURATION - CORE - {"date":"2024-06-14T10:26:24Z","os_name":"arm64-apple-darwin23","version":"2.1.0","lang":"ruby","lang_version":"3.3.2","env":null,"service":"rake","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.2","health_metrics_enabled":false,"profiling_enabled":false}
# I, [2024-06-14T12:26:24.691359 #9738]  INFO -- datadog: [datadog] DATADOG CONFIGURATION - CORE - {"date":"2024-06-14T10:26:24Z","os_name":"arm64-apple-darwin23","version":"2.1.0","lang":"ruby","lang_version":"3.3.2","env":null,"service":"rake","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.2","health_metrics_enabled":false,"profiling_enabled":false}
# I, [2024-06-14T12:26:25.627478 #10158]  INFO -- datadog: [datadog] DATADOG CONFIGURATION - CORE - {"date":"2024-06-14T10:26:25Z","os_name":"arm64-apple-darwin23","version":"2.1.0","lang":"ruby","lang_version":"3.3.2","env":null,"service":"rails","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.2","health_metrics_enabled":false,"profiling_enabled":false}
# I, [2024-06-14T12:26:25.772928 #10158]  INFO -- datadog: [datadog] DATADOG CONFIGURATION - CORE - {"date":"2024-06-14T10:26:25Z","os_name":"arm64-apple-darwin23","version":"2.1.0","lang":"ruby","lang_version":"3.3.2","env":null,"service":"rails","dd_version":null,"debug":false,"tags":null,"runtime_metrics_enabled":false,"vm":"ruby-3.3.2","health_metrics_enabled":false,"profiling_enabled":false}
#                            Prefix Verb   URI Pattern                                         Controller#Action
#                     gem_downloads GET    /gem_downloads(.:format)                            gem_downloads#index
#                                   POST   /gem_downloads(.:format)                            gem_downloads#create
#                  new_gem_download GET    /gem_downloads/new(.:format)                        gem_downloads#new
#                 edit_gem_download GET    /gem_downloads/:id/edit(.:format)                   gem_downloads#edit
#                      gem_download GET    /gem_downloads/:id(.:format)                        gem_downloads#show
#                                   PATCH  /gem_downloads/:id(.:format)                        gem_downloads#update
#                                   PUT    /gem_downloads/:id(.:format)                        gem_downloads#update
#                                   DELETE /gem_downloads/:id(.:format)                        gem_downloads#destroy
#             version_import_errors GET    /version_import_errors(.:format)                    version_import_errors#index
#                data_summary_index GET    /data_summary(.:format)                             data_summary#index
#                   search_versions GET    /versions/search(.:format)                          versions#search
#                          versions GET    /versions(.:format)                                 versions#index
#                           version GET    /versions/:id(.:format)                             versions#show
#                          raw_blob GET    /blobs/:sha256/raw(.:format)                        blobs#raw
#                             blobs GET    /blobs(.:format)                                    blobs#index
#                              blob GET    /blobs/:sha256(.:format)                            blobs#show
#                   search_rubygems GET    /rubygems/search(.:format)                          rubygems#search
#                      diff_rubygem GET    /rubygems/:name/diff(.:format)                      rubygems#diff
#         diff_rubygem_file_history GET    /rubygems/:rubygem_name/file_history/diff(.:format) file_histories#diff
#              rubygem_file_history GET    /rubygems/:rubygem_name/file_history(.:format)      file_histories#show
#                          rubygems GET    /rubygems(.:format)                                 rubygems#index
#                           rubygem GET    /rubygems/:name(.:format)                           rubygems#show
#                       hook_server POST   /servers/:id/hook(.:format)                         servers#hook
#                           servers GET    /servers(.:format)                                  servers#index
#                            server GET    /servers/:id(.:format)                              servers#show
#       search_version_data_entries GET    /version_data_entries/search(.:format)              version_data_entries#search
#                rails_health_check GET    /up(.:format)                                       rails/health#show
#                              root GET    /                                                   servers#index
#                          good_job        /good_job                                           GoodJob::Engine
#                 maintenance_tasks        /maintenance_tasks                                  MaintenanceTasks::Engine
#                           pg_hero        /pghero                                             PgHero::Engine
#                               avo        /avo                                                Avo::Engine
#                          debugbar        /_debugbar                                          Debugbar::Engine
#  turbo_recede_historical_location GET    /recede_historical_location(.:format)               turbo/native/navigation#recede
#  turbo_resume_historical_location GET    /resume_historical_location(.:format)               turbo/native/navigation#resume
# turbo_refresh_historical_location GET    /refresh_historical_location(.:format)              turbo/native/navigation#refresh
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
#
# Routes for Avo::Engine:
#                                   root GET    /                                                                                                  avo/home#index
#                              resources GET    /resources(.:format)                                                                               redirect(301, /avo)
#                             dashboards GET    /dashboards(.:format)                                                                              redirect(301, /avo)
#    rails_active_storage_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                     active_storage/direct_uploads#create
#                         avo_api_search GET    /avo_api/search(.:format)                                                                          avo/search#index
#                                avo_api GET    /avo_api/:resource_name/search(.:format)                                                           avo/search#show
#                                        POST   /avo_api/resources/:resource_name/:id/attachments(.:format)                                        avo/attachments#create
#                         failed_to_load GET    /failed_to_load(.:format)                                                                          avo/home#failed_to_load
#                                        DELETE /resources/:resource_name/:id/active_storage_attachments/:attachment_name/:attachment_id(.:format) avo/attachments#destroy
#                                        GET    /resources/:resource_name(/:id)/actions(/:action_id)(.:format)                                     avo/actions#show
#                                        POST   /resources/:resource_name(/:id)/actions(/:action_id)(.:format)                                     avo/actions#handle
# preview_resources_version_import_error GET    /resources/version_import_errors/:id/preview(.:format)                                             avo/version_import_errors#preview
#        resources_version_import_errors GET    /resources/version_import_errors(.:format)                                                         avo/version_import_errors#index
#                                        POST   /resources/version_import_errors(.:format)                                                         avo/version_import_errors#create
#     new_resources_version_import_error GET    /resources/version_import_errors/new(.:format)                                                     avo/version_import_errors#new
#    edit_resources_version_import_error GET    /resources/version_import_errors/:id/edit(.:format)                                                avo/version_import_errors#edit
#         resources_version_import_error GET    /resources/version_import_errors/:id(.:format)                                                     avo/version_import_errors#show
#                                        PATCH  /resources/version_import_errors/:id(.:format)                                                     avo/version_import_errors#update
#                                        PUT    /resources/version_import_errors/:id(.:format)                                                     avo/version_import_errors#update
#                                        DELETE /resources/version_import_errors/:id(.:format)                                                     avo/version_import_errors#destroy
#   preview_resources_version_data_entry GET    /resources/version_data_entries/:id/preview(.:format)                                              avo/version_data_entries#preview
#         resources_version_data_entries GET    /resources/version_data_entries(.:format)                                                          avo/version_data_entries#index
#                                        POST   /resources/version_data_entries(.:format)                                                          avo/version_data_entries#create
#       new_resources_version_data_entry GET    /resources/version_data_entries/new(.:format)                                                      avo/version_data_entries#new
#      edit_resources_version_data_entry GET    /resources/version_data_entries/:id/edit(.:format)                                                 avo/version_data_entries#edit
#           resources_version_data_entry GET    /resources/version_data_entries/:id(.:format)                                                      avo/version_data_entries#show
#                                        PATCH  /resources/version_data_entries/:id(.:format)                                                      avo/version_data_entries#update
#                                        PUT    /resources/version_data_entries/:id(.:format)                                                      avo/version_data_entries#update
#                                        DELETE /resources/version_data_entries/:id(.:format)                                                      avo/version_data_entries#destroy
#              preview_resources_version GET    /resources/versions/:id/preview(.:format)                                                          avo/versions#preview
#                     resources_versions GET    /resources/versions(.:format)                                                                      avo/versions#index
#                                        POST   /resources/versions(.:format)                                                                      avo/versions#create
#                  new_resources_version GET    /resources/versions/new(.:format)                                                                  avo/versions#new
#                 edit_resources_version GET    /resources/versions/:id/edit(.:format)                                                             avo/versions#edit
#                      resources_version GET    /resources/versions/:id(.:format)                                                                  avo/versions#show
#                                        PATCH  /resources/versions/:id(.:format)                                                                  avo/versions#update
#                                        PUT    /resources/versions/:id(.:format)                                                                  avo/versions#update
#                                        DELETE /resources/versions/:id(.:format)                                                                  avo/versions#destroy
#               preview_resources_server GET    /resources/servers/:id/preview(.:format)                                                           avo/servers#preview
#                      resources_servers GET    /resources/servers(.:format)                                                                       avo/servers#index
#                                        POST   /resources/servers(.:format)                                                                       avo/servers#create
#                   new_resources_server GET    /resources/servers/new(.:format)                                                                   avo/servers#new
#                  edit_resources_server GET    /resources/servers/:id/edit(.:format)                                                              avo/servers#edit
#                       resources_server GET    /resources/servers/:id(.:format)                                                                   avo/servers#show
#                                        PATCH  /resources/servers/:id(.:format)                                                                   avo/servers#update
#                                        PUT    /resources/servers/:id(.:format)                                                                   avo/servers#update
#                                        DELETE /resources/servers/:id(.:format)                                                                   avo/servers#destroy
#              preview_resources_rubygem GET    /resources/rubygems/:id/preview(.:format)                                                          avo/rubygems#preview
#                     resources_rubygems GET    /resources/rubygems(.:format)                                                                      avo/rubygems#index
#                                        POST   /resources/rubygems(.:format)                                                                      avo/rubygems#create
#                  new_resources_rubygem GET    /resources/rubygems/new(.:format)                                                                  avo/rubygems#new
#                 edit_resources_rubygem GET    /resources/rubygems/:id/edit(.:format)                                                             avo/rubygems#edit
#                      resources_rubygem GET    /resources/rubygems/:id(.:format)                                                                  avo/rubygems#show
#                                        PATCH  /resources/rubygems/:id(.:format)                                                                  avo/rubygems#update
#                                        PUT    /resources/rubygems/:id(.:format)                                                                  avo/rubygems#update
#                                        DELETE /resources/rubygems/:id(.:format)                                                                  avo/rubygems#destroy
#                 preview_resources_blob GET    /resources/blobs/:id/preview(.:format)                                                             avo/blobs#preview
#                        resources_blobs GET    /resources/blobs(.:format)                                                                         avo/blobs#index
#                                        POST   /resources/blobs(.:format)                                                                         avo/blobs#create
#                     new_resources_blob GET    /resources/blobs/new(.:format)                                                                     avo/blobs#new
#                    edit_resources_blob GET    /resources/blobs/:id/edit(.:format)                                                                avo/blobs#edit
#                         resources_blob GET    /resources/blobs/:id(.:format)                                                                     avo/blobs#show
#                                        PATCH  /resources/blobs/:id(.:format)                                                                     avo/blobs#update
#                                        PUT    /resources/blobs/:id(.:format)                                                                     avo/blobs#update
#                                        DELETE /resources/blobs/:id(.:format)                                                                     avo/blobs#destroy
#             resources_associations_new GET    /resources/:resource_name/:id/:related_name/new(.:format)                                          avo/associations#new
#           resources_associations_index GET    /resources/:resource_name/:id/:related_name(.:format)                                              avo/associations#index
#            resources_associations_show GET    /resources/:resource_name/:id/:related_name/:related_id(.:format)                                  avo/associations#show
#          resources_associations_create POST   /resources/:resource_name/:id/:related_name(.:format)                                              avo/associations#create
#         resources_associations_destroy DELETE /resources/:resource_name/:id/:related_name/:related_id(.:format)                                  avo/associations#destroy
#                     avo_private_status GET    /avo_private/status(.:format)                                                                      avo/debug#status
#                 avo_private_send_to_hq POST   /avo_private/status/send_to_hq(.:format)                                                           avo/debug#send_to_hq
#               avo_private_debug_report GET    /avo_private/debug/report(.:format)                                                                avo/debug#report
#      avo_private_debug_refresh_license POST   /avo_private/debug/refresh_license(.:format)                                                       avo/debug#refresh_license
#                     avo_private_design GET    /avo_private/design(.:format)                                                                      avo/private#design
#
# Routes for Debugbar::Engine:
#                       /cable                   #<ActionCable::Server::Base:0x0000000127151558 @config=#<ActionCable::Server::Configuration:0x00000001271544d8 @log_tags=[], @connection_class=#<Proc:0x000000012637b780 /Users/segiddins/.gem/ruby/3.3.2/gems/actioncable-7.1.3.4/lib/action_cable/engine.rb:53 (lambda)>, @worker_pool_size=4, @disable_request_forgery_protection=false, @allow_same_origin_as_host=true, @filter_parameters=[:passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn], @health_check_application=#<Proc:0x0000000126b72538 /Users/segiddins/.gem/ruby/3.3.2/gems/actioncable-7.1.3.4/lib/action_cable/engine.rb:29 (lambda)>, @logger=#<SemanticLogger::Logger:0x0000000127153cb8 @filter=nil, @name="ActionCable", @level_index=nil, @level=nil>, @cable={"adapter"=>"async"}, @mount_path="/cable", @precompile_assets=true, @allowed_request_origins=/https?:\/\/localhost:\d+/>, @mutex=#<Monitor:0x0000000125ffff98>, @pubsub=nil, @worker_pool=nil, @event_loop=nil, @remote_connections=nil>
#          poll GET     /poll(.:format)          debugbar/polling#poll
#  poll_confirm OPTIONS /poll/confirm(.:format)  debugbar/polling#confirm
#               POST    /poll/confirm(.:format)  debugbar/polling#confirm
# assets_script GET     /assets/script(.:format) debugbar/assets#js

Rails.application.routes.draw do
  resources :gem_downloads
  resources :version_import_errors, only: [:index]
  resources :data_summary, only: [:index]

  resources :versions, only: [:show, :index] do
    get :search, on: :collection
    get :gemspec, on: :member, defaults: { format: :gemspec }
  end
  special_characters    = ".-_".freeze
  allowed_characters    = "[A-Za-z0-9#{Regexp.escape(special_characters)}]+".freeze
  route_pattern          = /#{allowed_characters}/

  resources :blobs, only: %i[show index], param: :sha256 do
    member do
      get :raw
    end
  end
  resources :rubygems, only: %i[show index], param: :name, constraints: { id: route_pattern } do
    get :search, on: :collection
    get :diff, on: :member
    resource :file_history, only: [:show], param: :path, constraints: { id: /.+/} do
      get :diff
    end
  end
  resources :servers, only: %i[show index] do
    member do
      post :hook
    end
  end

  resources :version_data_entries, only: %i[] do
    get :search, on: :collection
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "servers#index"

  constraints ->(request) { request.local? || request.remote_ip == "100.86.251.32" || request.host == "rubygems-research-1.folk-dinosaur.ts.net" } do
    mount GoodJob::Engine, at: '/good_job'
    mount MaintenanceTasks::Engine, at: "/maintenance_tasks"
    mount PgHero::Engine, at: "/pghero"
    mount Avo::Engine, at: Avo.configuration.root_path
    mount(Debugbar::Engine => Debugbar.config.prefix) if defined?(Debugbar)
  end
end
