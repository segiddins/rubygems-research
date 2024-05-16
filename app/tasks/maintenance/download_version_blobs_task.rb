# frozen_string_literal: true

require 'rubygems/package'

class Maintenance::DownloadVersionBlobsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable
  attribute :gem_name, :string

  throttle_on(backoff: 1.second) do
    rand < 0.02
  end

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
      VersionImportError.create!(version: version, error: "Missing SHA256 for #{version.full_name}")
      return
    end
    unless version.spec_sha256.present?
      VersionImportError.create!(version: version, error: "Missing spec SHA256 for #{version.full_name}")
      return
    end

    DownloadVersionBlobsJob.new.perform(version: version)
  rescue Gem::Package::FormatError, Gem::Package::TarInvalidError => e
    VersionImportError.where(version:).find_or_initialize.update!(e.message)
  end
end
