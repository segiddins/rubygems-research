# frozen_string_literal: true

JobIteration::InterruptionAdapters.module_eval do
  unless defined?(GoodJobAdapter)
    # from https://github.com/Shopify/job-iteration/pull/464
    module GoodJobAdapter
      class << self
        def call
          !!::GoodJob.current_thread_shutting_down?
        end
      end
    end

    register(:good_job, GoodJobAdapter)
  end
end
