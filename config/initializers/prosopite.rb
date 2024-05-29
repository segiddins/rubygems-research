if Rails.env.local?
  require 'prosopite/middleware/rack'
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)

  Rails.application.config.after_initialize do
    Prosopite.custom_logger = SemanticLogger[Prosopite]
    Prosopite.raise = true
    Prosopite.ignore_queries = []
    Prosopite.allow_stack_paths = []
  end
end
