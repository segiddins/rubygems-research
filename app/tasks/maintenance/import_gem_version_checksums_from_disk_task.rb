# frozen_string_literal: true

module Maintenance
  class ImportGemVersionChecksumsFromDiskTask < MaintenanceTasks::Task
    include SemanticLogger::Loggable

    def enumerator_builder(cursor:)
      out, status = Open3.capture2("duckdb", "--json", "-c", <<~CMD)
        LOAD postgres;
        ATTACH 'host=localhost port=5432 dbname=rubygems_production' AS prod (TYPE postgres);
        SELECT rubygems.name, versions.number, versions.platform, versions.sha256, versions.spec_sha256, versions.id as version_id
        from prod.versions join prod.rubygems on versions.rubygem_id = rubygems.id
        #{"where versions.id > #{cursor}" if cursor}
        ;
      CMD
      raise "Failed to execute query" unless status.success?
      JSON.load(out).map! do |row|
        [row, row["version_id"].to_s]
      end.to_enum
    end

    def process(hash)
      rubygem = Rubygem.find_by!(name: hash["name"], server_id: 1)
      version = rubygem.versions.find_by!(number: hash["number"], platform: hash["platform"])
      sha256, spec_sha256 = hash.values_at('sha256', 'spec_sha256').map! { _1 && Base64.decode64(_1)&.unpack1("H*") }
      version.update!(sha256:, spec_sha256:)
    rescue ActiveRecord::RecordNotFound => e
      logger.warn "Failed to find version for #{hash['name']} #{hash['number']} #{hash['platform']}: #{e.message}"
    end
  end
end
