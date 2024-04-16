class DownloadVersionBlobsJob < ApplicationJob
  queue_as :default

  def perform(version:)
    if version.sha256.nil?
      raise "Version #{version.id} has no sha256"
    end

    if version.spec_sha256.nil?
      raise "Version #{version.id} has no spec_sha256"
    end

    unless version.package_blob.present?
      resp = Faraday.get("#{version.server.url}/gems/#{version.full_name}.gem", nil, { "Accept" => "application/octet-stream" })
      if resp.status != 200
        raise "Failed to download gem: #{resp.status}"
      end

      contents = resp.body
      sha256 = Digest::SHA256.hexdigest(contents)
      raise "Checksum mismatch, expected: #{version.sha256} got: #{sha256}" unless sha256 == version.sha256
      gem_blob = Blob.create!(contents:, sha256:, size: contents.size)
    end

    unless version.quick_spec_blob.present?
      resp = Faraday.get("#{version.server.url}/quick/Marshal.4.8/#{version.full_name}.gemspec.rz", nil, { "Accept" => "application/octet-stream" })
      if resp.status != 200
        raise "Failed to download quick spec: #{resp.status}"
      end

      contents = resp.body
      sha256 = Digest::SHA256.hexdigest(contents)
      raise "Checksum mismatch, expected: #{version.spec_sha256} got: #{sha256}" unless sha256 == version.spec_sha256
      quick_spec_blob = Blob.create!(contents:, sha256:, size: contents.size)
    end

    version
  end
end
