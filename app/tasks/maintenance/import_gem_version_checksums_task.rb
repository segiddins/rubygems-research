# frozen_string_literal: true

module Maintenance
  class ImportGemVersionChecksumsTask < MaintenanceTasks::Task
    include SemanticLogger::Loggable

    attribute :rubygem_name, :string

    def collection
      Version.then {rubygem_name.present? ? _1.joins(:rubygem).where(rubygem: { name: rubygem_name}) : _1 }.includes(:rubygem, :server).all
    end

    def connection
      @connection ||= Faraday.new(url: 'http://httpbingo.org') do |builder|
        # Parses JSON response bodies.
        # If the response body is not valid JSON, it will raise a Faraday::ParsingError.
        builder.response :json

        # Raises an error on 4xx and 5xx responses.
        builder.response :raise_error

        # Logs requests and responses.
        # By default, it only logs the request method and URL, and the request/response headers.
        # builder.response :logger, logger
      end
    end

    def process(version)
      url = "#{version.server.url}/api/v2/rubygems/#{version.rubygem.name}/versions/#{version.number}.json"
      url << "?platform=#{version.platform}" if version.platformed?
      response = connection.get(url)
      sha256, spec_sha256 = response.body.values_at('sha', 'spec_sha')
      if version.sha256.present? && version.sha256 != sha256
        raise "SHA256 mismatch for #{version.full_name}: expected #{version.sha256}, got #{sha256}"
      end
      if version.spec_sha256.present? && version.spec_sha256 != spec_sha256
        raise "Spec SHA256 mismatch for #{version.full_name}: expected #{version.spec_sha256}, got #{spec_sha256}"
      end
      version.update!(sha256:, spec_sha256:)
    rescue Faraday::ResourceNotFound => e
      logger.warn("Version not found on server", version: version.full_name, server: version.server.url)
    end
  end
end
