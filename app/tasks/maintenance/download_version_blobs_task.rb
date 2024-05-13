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
      .where.not(sha256: nil)
      .where(**where)
      .includes(:package_blob_with_contents)
  end

  def process(version)
    raise "Missing SHA256 for #{version.full_name}" unless version.sha256.present?
    raise "Missing spec SHA256 for #{version.full_name}" unless version.spec_sha256.present?

    DownloadVersionBlobsJob.new.perform(version: version)
  end
end
