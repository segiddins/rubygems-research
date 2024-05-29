# frozen_string_literal: true

module JobIteration
  module InterruptionAdapters
    unless defined?(GoodJobAdapter)
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
end
