if Rails.env.local?
  require 'prosopite/middleware/rack'
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)

  Rails.application.config.after_initialize do
    Prosopite.custom_logger = SemanticLogger[Prosopite]
    Prosopite.raise = true
    Prosopite.ignore_queries = [
      /SELECT COUNT\(\*\)/,
      %[SELECT SUM("blobs"."size") FROM "blobs" INNER JOIN "versions" ON "blobs"."sha256" = "versions"."sha256" WHERE "versions"."rubygem_id" = $1]
    ]
    Prosopite.allow_stack_paths = []
  end
end
