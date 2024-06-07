class DownloadVersionBlobsJob < ApplicationJob
  queue_as :default

  class Error < StandardError; end
  class SHA256Mismatch < Error; end
  class DuplicateEntry < Error; end
  class UnexpectedEntry < Error; end
  class MissingSHA256 < Error; end
  class RequestError < Error; end
  class GZIPReadError < Error; end

  cattr_accessor(:server_client) do
    Faraday.new do |conn|
      conn.request :instrumentation
      conn.response :logger, logger
    end
  end

  rescue_from Faraday::TimeoutError, with: :retry_job
  discard_on Error

  def perform(version:)
    logger.info "Downloading blobs for #{version.full_name} (#{version.id})"
    if version.sha256.nil?
      raise MissingSHA256, "Version has no sha256"
    end

    if version.spec_sha256.nil?
      logger.warn "Version #{version.id} (#{version.full_name}) has no spec_sha256"
    end

    gem_blob =
      if version.package_blob_with_contents.present? && version.package_blob_with_contents.contents.present?
        version.package_blob_with_contents
      elsif version.indexed
        resp = server_client.get("#{version.server.url}/gems/#{version.full_name}.gem", nil, { "Accept" => "application/octet-stream" })
        if resp.status != 200
          raise RequestError, "Failed to download gem: #{resp.status}"
        end

        contents = resp.body
        sha256 = Digest::SHA256.hexdigest(contents)
        unless sha256 == version.sha256
          raise SHA256Mismatch, "SHA256 Checksum mismatch"
        end
        import_blobs([Blob.new(contents:, sha256:, size: contents.size)]).sole
      else
        logger.warn "Version #{version.id} (#{version.full_name}) is not indexed"
        return
      end

    source_date_epoch, metadata_blob, entries = read_package(version, gem_blob)
    logger.info "Downloaded blobs for #{version.full_name} (#{version.id})", source_date_epoch: source_date_epoch

    import_blobs(entries.map(&:blob).uniq)
    VersionDataEntry.import!(
      entries,
      on_duplicate_key_update: {
        conflict_target: [:full_name, :version_id], columns: [:blob_id, :gid, :linkname, :mode, :mtime, :name, :uid],
      }
    )

    version.metadata_blob_id = import_blobs([metadata_blob]).sole.id

    if version.spec_sha256.present? && !version.quick_spec_blob.present? && version.indexed
      resp = server_client.get("#{version.server.url}/quick/Marshal.4.8/#{version.full_name}.gemspec.rz", nil, { "Accept" => "application/octet-stream" })
      if resp.status != 200
        raise RequestError, "Failed to download quick spec: #{resp.status}"
      end

      contents = resp.body
      sha256 = Digest::SHA256.hexdigest(contents)
      raise SHA256Mismatch, "spec sha256 checksum mismatch" unless sha256 == version.spec_sha256
      _quick_spec_blob = Blob.create!(contents:, sha256:, size: contents.size)
    end

    version.save!

    version.as_json

    # {
    #   version:,
    #   metadata_blob: metadata_blob,
    #   quick_spec_blob: version.quick_spec_blob,
    #   entries: version.version_data_entries.joins(:blob).pluck(:id, :sha256, 'blobs.id'),
    # }
  end

  private

  def read_package(version, blob)
    source_date_epoch = metadata = entries = nil

    pkg = Gem::Package.new(StringIO.new(blob.decompressed_contents))
    pkg.gem.with_read_io do |io|
      reader = Gem::Package::TarReader.new io

      reader.each do |entry|
        logger.info "mismatched source_date_epoch: #{source_date_epoch} vs #{entry.header.mtime} in #{entry.full_name} in #{version.full_name}" if source_date_epoch && source_date_epoch != entry.header.mtime
        source_date_epoch = entry.header.mtime

        case entry.header.name
        when "metadata.gz"
          raise DuplicateEntry, "metadata.gz already present" if metadata
          metadata = read_already_gzipped(entry)
        when "data.tar.gz"
          raise DuplicateEntry, "data.tar.gz already present" if entries
          entries = read_data_tar_gz(version, entry)
        when "checksums.yaml.gz.asc",
         "checksums.yaml.gz.sig",
         "checksums.yaml.gz",
         "credentials.tar.gz",
         "data.tar.gz.asc",
         "data.tar.gz.sig",
         "metadata.gz.asc",
         "metadata.gz.sig"

          logger.info "skipping #{entry.header.name}"
        else
          raise UnexpectedEntry, "unexpected file in gem: #{entry.header.name}"
        end
      end
    rescue Gem::Package::TarInvalidError => e
      logger.error message: "Failed to read gem", exception: e, version: version.full_name, version_id: version.id
      raise
    end

    return source_date_epoch, metadata, (entries || [])
  end

  def read_data_tar_gz(version, io)
    Zlib::GzipReader.wrap(io) do |gz|
      tar = Gem::Package::TarReader.new(gz)
      tar.map do |entry|
        entry_to_blob(version, entry)
      end
    end.tap do |entries|
      if entries.empty?
        logger.warn "no entries in data.tar.gz in #{version.id} #{version.pretty_inspect}"
      end
      # dedup blobs
      blobs = entries.map(&:blob).to_h { |blob| [blob.sha256, blob] }
      entries.each do |entry|
        entry.blob = blobs[entry.blob.sha256]
      end
    end
  end

  def read_already_gzipped(io)
    gzipped = io.read
    contents = Zlib.gunzip(gzipped)

    sha256 = Digest::SHA256.hexdigest(contents)
    size = contents.size

    Blob.new(contents: gzipped, compression: "gzip", sha256:, size:)
  end

  def entry_to_blob(version, entry)
    begin
      contents = entry.read
    rescue => e
      logger.error message: "Failed to read entry", exception: e, entry: entry.as_json
      raise GZIPReadError, e.message
    end
    size = contents.size
    sha256 = Digest::SHA256.hexdigest(contents)
    compression = nil
    if entry.header.size != size
      raise "size mismatch: expected #{entry.header.size}, got #{size}"
    end

    VersionDataEntry.build(
      version: version,
      full_name: entry.full_name,
      gid: entry.header.gid,
      linkname: entry.header.linkname,
      mode: entry.header.mode,
      mtime: entry.header.mtime,
      name: File.basename(entry.header.name),
      sha256:,
      uid: entry.header.uid,
      blob: Blob.new(contents:, compression:, sha256:, size:),
    )
  end

  def import_blobs(blobs)
    ids = Blob.where(sha256: blobs.pluck(:sha256))
      .where("contents is not null")
      .pluck(:sha256, :id).to_h

    logger.info "Importing #{blobs.size} blobs, #{ids.size} already present"

    missing = []
    blobs.each do |blob|
      if ids.key?(blob.sha256)
        blob.id = ids[blob.sha256]
      else
        compress_if_needed(blob)
        missing << blob
      end
    end

    missing.each_with_object([[]]) do |elem, acc|
      s = acc.last
      if elem.contents.size >= 100.megabytes
        logger.warn "Blob too large to store via activerecord-import", sha256: elem.sha256, size: elem.size
        elem.save!
        next
      end
      if s.sum { _1.contents&.size || 0 } + elem.size < 100.megabytes
        s << elem
      else
        acc << [elem]
      end
    end.each do |chunk|
      logger.info "Importing #{chunk.size} blobs totalling #{chunk.sum { _1.contents&.size || 0 }} bytes"
      Blob.import!(
        chunk,
        on_duplicate_key_update: {
          conflict_target: [:sha256], columns: [:compression, :contents, :size],
          index_predicate: "blobs.contents is null"
        },
      )
    end

    blobs
  rescue ActiveRecord::StatementInvalid => e
    logger.error message: "Failed to import blobs", exception: e, sql_size: e.sql.size
    raise
  end

  def compress_if_needed(blob)
    return if blob.compression

    if blob.size > 2 * 1024
      compressed = Zlib.gzip(blob.contents)
      if compressed.size < blob.size * 0.9 # only compress if it saves 10%
        blob.compression = "gzip"
        blob.contents = compressed
      end
    end
  end
end
