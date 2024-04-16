# frozen_string_literal: true

require 'rubygems/package'

class Maintenance::ImportGemFileTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable
  attribute :gem_name, :string
  attribute :store_gem_packages, :boolean, default: false
  attribute :store_entry_contents, :boolean, default: false

  throttle_on(backoff: 1.second) do
    rand < 0.02
  end

  class SHA256Mismatch < StandardError; end

  def collection
    Version.where.not(sha256: nil)
    .then { |q| gem_name.present? ? q.joins(:rubygem).where(rubygem: {name: gem_name}) : q }
    .includes(:rubygem, :server).all
  end

  def process(version)
    raise "Missing SHA256 for #{version.full_name}" unless version.sha256.present?
    raise "Missing spec SHA256 for #{version.full_name}" unless version.spec_sha256.present?
    contents = Gem.read_binary("/Users/segiddins/Development/github.com/akr/gem-codesearch/mirror/gems/#{version.full_name}.gem")
    store_blob(contents, compression: nil, expected_sha256: version.sha256, include_contents: store_gem_packages)

    package = Gem::Package.new(StringIO.new(contents))
    # Skip verify. it is slow, and we know the gem is fine (ish) because the SHA256 matched
    # package.verify
    enumerate_package(version, package)

    contents = Gem.read_binary("/Users/segiddins/Development/github.com/akr/gem-codesearch/mirror/quick/Marshal.4.8/#{version.full_name}.gemspec.rz")
    store_blob(contents, compression: nil, expected_sha256: version.spec_sha256, include_contents: true)

    version.save!
    nil
  rescue Gem::Package::FormatError, Encoding::UndefinedConversionError, Gem::Package::TarInvalidError, Psych::SyntaxError, SHA256Mismatch => e
    logger.error "Error processing #{version.full_name}: #{e.message}"
    e
  rescue ArgumentError => e
    if e.message == "invalid byte sequence in UTF-8"
      logger.error "Error processing #{version.full_name}: #{e.message}"
      e
    else
      raise "[#{e.class}] Error processing #{version.full_name}: #{e.message}\n#{e.backtrace.join("\n\t")}"
    end
  rescue StandardError => e
    raise "[#{e.class}] Error processing #{version.full_name}: #{e.message}\n#{e.backtrace.join("\n\t")}"
  end

  def enumerate_package(version, package)
    package.gem.with_read_io do |io|
      Gem::Package::TarReader.new io do |reader|
        reader.each do |entry|
          case entry.full_name
          when "metadata" then
            store_metadata_blob version, entry.read
          when "metadata.gz" then
            Zlib::GzipReader.wrap(entry, external_encoding: Encoding::UTF_8) do |gzio|
              store_metadata_blob version, gzio.read
            end
          when "data.tar.gz" then
            package.open_tar_gz(entry) do |tar|
              enumerate_data_tar(version, tar)
            end
          end
        end
      end
    end
  end

  def store_metadata_blob(version, contents)
    version.metadata_blob_id = store_blob(contents, compression: "gzip", include_contents: true)
  end

  def enumerate_data_tar(version, tar)
    tar.each do |tar_entry|
      blob_id = store_blob(tar_entry.read, compression: "gzip", expected_sha256: nil, include_contents: store_entry_contents) if tar_entry.file?
      version_data_entry = create_or_find_data_entry!(version.version_data_entries, tar_entry)
    end
  end

  def create_or_find_data_entry!(version_data_entries, tar_entry, blob_id: nil)
    full_name = tar_entry.full_name.force_encoding('UTF-8')
    version_data_entries.create_with(
      name: File.basename(full_name),
      mode: tar_entry.header.mode,
      uid: tar_entry.header.uid,
      gid: tar_entry.header.gid,
      mtime: tar_entry.header.mtime,
      linkname: tar_entry.header.linkname,
      blob_id: blob_id,
    ).create_or_find_by!(full_name:)
  end

  def store_blob(contents, compression:, expected_sha256: nil, include_contents: true)
    sha256 = Digest::SHA256.hexdigest(contents)

    if expected_sha256 && sha256 != expected_sha256
      raise SHA256Mismatch, "SHA256 mismatch: expected #{expected_sha256}, got #{sha256}"
    end

    size = contents.bytesize

    case compression
    when nil
      compressed = contents
    when "gzip"
      if size < 2048 || !include_contents # if the file is less than 2k bytes, don't bother compressing
        compressed = contents
        compression = nil
      else
        compressed = Zlib.gzip(contents)
        if compressed.bytesize - size < 1024 # if savings are less than 1KB, don't bother compressing
            compressed = contents
            compression = nil
        end
      end
    else
      raise "Unknown compression: #{compression}"
    end

    if !include_contents
      compressed = nil
      compression = nil
    end



    Blob.where(sha256:, size:).pick(:id) ||
      Blob.create_with(contents: compressed, compression: "gzip")
        .excluding_contents
        .create!(sha256:, size:).id
  end
end
