# frozen_string_literal: true

module Maintenance
  class ImportGemVersionsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable
    def collection
      Server.all
    end

    def process(server)
      source = Gem::SourceList.from([server.url]).sole
      fetcher = Gem::SpecFetcher.fetcher
      prerelease = fetcher.tuples_for(source, :prerelease, true)
      logger.info "Importing #{prerelease.size} prerelease versions for #{server.url}"
      released = fetcher.tuples_for(source, :released)
      logger.info "Importing #{released.size} released versions for #{server.url}"
      tuples = prerelease + released
      tuples = tuples.group_by(&:name)

      rubygems = server.rubygems.pluck(:name)
      Rubygem.import!(tuples.keys.-(rubygems).map { |name| {name: name, server_id: server.id} })
      rubygems = server.rubygems.pluck(:name, :id).to_h
      existing = server.rubygems.joins(:versions).pluck(:name, 'versions.number', 'versions.platform').to_set

      versions = tuples.flat_map do |name, tuples_for_name|
        unless rubygem_id = rubygems[name]
          raise "No rubygem found for #{name} on #{server.url}"
        end

        tuples_for_name.map do |tuple|
          next if existing.include?([name, tuple.version.to_s, tuple.platform.to_s])

          new_rubygems[name] = rubygem_id
          {rubygem_id:, number: tuple.version.to_s, platform: tuple.platform.to_s}
        end
      end.compact

      # logger.info "Importing #{rubygems.size} rubygems for #{server.url}"
      # Rubygem.import!(versions, on_duplicate_key_ignore: true, batch_size: 10_000)

      logger.info "Importing #{versions.size} versions for #{server.url}"
      Version.import!(versions)
    end
  end
end
