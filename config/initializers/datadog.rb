Datadog.configure do |c|
   # unified service tagging

   c.service = "rubygems-research"
   c.version = ENV.fetch("APP_VERSION") { "unknown" }.strip
   c.env = Rails.env

   # Enabling datadog functionality

   enabled = !Rails.env.local? && !defined?(Rails::Console)
   c.runtime_metrics.enabled = enabled
   c.profiling.enabled = enabled
   c.tracing.enabled = enabled
   c.tracing.log_injection = enabled
   c.telemetry.enabled = enabled
   c.remote.enabled = enabled

   unless enabled
     # TODO: https://github.com/DataDog/dd-trace-rb/issues/2542
     # disable log tags loaded super early by ddtrace/auto_instrument
     # required in Gemfile, since they are polluting development log
     original_tags = Array.wrap(Rails.application.config.log_tags).reject { |tag| tag.try(:source_location)&.first&.include?('datadog') }
     Rails.application.config.log_tags = original_tags

     c.tracing.transport_options = proc { |t|
       # Set transport to no-op mode. Does not retain traces.
       t.adapter :test
     }
     c.diagnostics.startup_logs.enabled = false
   end

   # Configuring the datadog library

   c.logger.instance = SemanticLogger[Datadog]

   # Configuring tracing

   c.tracing.report_hostname = true
   c.tracing.distributed_tracing.propagation_inject_style << 'tracecontext'
   c.tracing.distributed_tracing.propagation_extract_style << 'tracecontext'

   c.tracing.instrument :faraday, split_by_domain: true, service_name: c.service
   c.tracing.instrument :http, split_by_domain: true, service_name: c.service
   c.tracing.instrument :pg
   c.tracing.instrument :rails, request_queuing: true
   c.tracing.instrument :active_record
end
