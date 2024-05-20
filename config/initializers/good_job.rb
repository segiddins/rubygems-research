Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = true
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception, handled: false) }
  config.good_job.queues = '*'
  # Wait 20 seconds for jobs to finish before shutting down. The kubernetes grace
  # period is 30 seconds so forcing a shutdown after 20 seconds will allow good_job
  # to handle the shutdown somewhat gracefully.
  config.good_job.shutdown_timeout = 20
  config.good_job.logger = SemanticLogger[GoodJob]

  config.good_job.enable_cron = !Rails.env.development?
  config.good_job.smaller_number_is_higher_priority = true

  GoodJob.active_record_parent_class = "ApplicationRecord"

  if Rails.env.development? && GoodJob::CLI.within_exe?
    GoodJob::CLI.log_to_stdout = false

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console)) unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, $stderr, $stdout)

    ActiveRecord::Base.logger = nil
    GoodJob.logger = Rails.logger
  end

  if Rails.env.development? && defined?(Rails::Console)
    config.good_job.queues = ""
  end
end
