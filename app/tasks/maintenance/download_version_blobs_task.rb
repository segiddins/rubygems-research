# frozen_string_literal: true

require 'rubygems/package'

class Maintenance::DownloadVersionBlobsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable
  attribute :gem_name, :string

  class SHA256Mismatch < StandardError; end

  def collection
    where = { indexed: true }
    where[:rubygem] = { name: gem_name } if gem_name.present?
    Version.joins(:rubygem)
      .where(**where)
      .includes(:package_blob_with_contents)
  end

  def process(version)
    unless version.sha256.present?
      VersionImportError.find_or_initialize_by(version: version).update!(error: "Missing SHA256")
      return
    end
    unless version.spec_sha256.present?
      VersionImportError.find_or_initialize_by(version: version).update!(error: "Missing spec SHA256")
      return
    end

    DownloadVersionBlobsJob.new.perform(version: version)
  rescue Gem::Package::FormatError, Gem::Package::TarInvalidError => e
    logger.error "Failed to download blobs for #{version.full_name} (#{version.id})", exception: e
    VersionImportError.find_or_initialize_by(version:).update!(error: e.message)
  end
end
