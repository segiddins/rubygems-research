# Load the Rails application.
require_relative "application"

require 'datadog/profiling/preload'

# Initialize the Rails application.
Rails.application.initialize!
