# frozen_string_literal: true

require 'rubygems/package'

class Maintenance::DownloadVersionBlobsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable
  attribute :gem_name, :string
  attribute :only_errors, :boolean, default: false

  class SHA256Mismatch < StandardError; end

  def collection
    Version
      .where(indexed: true)
      .then { |q| gem_name.present? ? q.where(rubygem: Rubygem.where(server: Server.all.pluck(:id), name: gem_name)) : q }
      .then { |q| only_errors ? q.where.associated(:version_import_error) : q }
      .preload(:rubygem, :package_blob_with_contents, :server, :quick_spec_blob)
  end

  def process(version)
    unless version.sha256.present?
      VersionImportError.find_or_initialize_by(version: version).update!(error: "Missing SHA256")
      return
    end
    # unless version.spec_sha256.present?
    #   VersionImportError.find_or_initialize_by(version: version).update!(error: "Missing spec SHA256")
    #   return
    # end

    SemanticLogger.tagged(version: version.full_name, version_id: version.id, rubygem: version.rubygem.name) do
      DownloadVersionBlobsJob.new.perform(version: version)
      version.version_import_error&.destroy!
    end
  rescue Gem::Package::FormatError, Gem::Package::TarInvalidError, ActiveRecord::StatementInvalid, DownloadVersionBlobsJob::Error, Psych::AliasesNotEnabled => e
    if e.message.valid_encoding?
      logger.error message: "Failed to download blobs for #{version.full_name} (#{version.id})", exception: e
    else
      logger.error message: "Failed to download blobs for #{version.full_name} (#{version.id})", exception: e.class, error: e.message.scrub
    end
    VersionImportError.find_or_initialize_by(version:).update!(error: "#{e.class}: #{e.message}".scrub)
  end
end
