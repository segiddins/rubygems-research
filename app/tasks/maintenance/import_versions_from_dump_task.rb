# frozen_string_literal: true

module Maintenance
  class ImportVersionsFromDumpTask < MaintenanceTasks::Task
    include SemanticLogger::Loggable

    def collection
      Rubygem.where(server: Server.find_by!(url: "https://rubygems.org"))
    end

    def process(rubygem)
      batch = Dump::Version.joins(:rubygem).where(rubygem: { name: rubygem.name})
      batch.load
      logger.info "Processing #{batch.size} versions for #{rubygem.name}"
      Version.import!(
        batch.map do |element|
          {
            number: element.number,
            platform: element.platform,
            indexed: element.indexed,
            uploaded_at: element.created_at,
            metadata: element.metadata,
            sha256: base64_to_hex(element.sha256),
            spec_sha256: base64_to_hex(element.spec_sha256),
            rubygem_id: rubygem.id
          }
        end,
        on_duplicate_key_update: {
          conflict_target: [:rubygem_id, :number, :platform],
          columns: [:indexed, :uploaded_at, :metadata, :sha256, :spec_sha256],
          # index_predicate: "versions.indexed != excluded.indexed"
        },
        # on_duplicate_key_ignore: {
        #   conflict_target: [:rubygem_id, :number, :platform]
        # }
      )
      rubygem.bulk_reorder_versions
    end

    def base64_to_hex(base64)
      return unless base64.present?
      Base64.decode64(base64)&.unpack1("H*")
    end
  end
end
