# frozen_string_literal: true

JobIteration::InterruptionAdapters.module_eval do
  unless defined?(self::GoodJobAdapter)
    # from https://github.com/Shopify/job-iteration/pull/464
    module self::GoodJobAdapter
      class << self
        def call
          !!::GoodJob.current_thread_shutting_down?
        end
      end
    end

    register(:good_job, self::GoodJobAdapter)
  end
end
