class DownloadVersionBlobsJob < ApplicationJob
  queue_as :default

  def perform(version:)
    logger.info "Downloading blobs for #{version.full_name} (#{version.id})"
    if version.sha256.nil?
      raise "Version #{version.id} has no sha256"
    end

    if version.spec_sha256.nil?
      raise "Version #{version.id} (#{version.full_name}) has no spec_sha256"
    end

    gem_blob =
      if version.package_blob_with_contents.present?
        version.package_blob_with_contents
      else
        resp = Faraday.get("#{version.server.url}/gems/#{version.full_name}.gem", nil, { "Accept" => "application/octet-stream" })
        if resp.status != 200
          raise "Failed to download gem: #{resp.status}"
        end

        contents = resp.body
        sha256 = Digest::SHA256.hexdigest(contents)
        raise "Checksum mismatch, expected: #{version.sha256} got: #{sha256}" unless sha256 == version.sha256
        import_blobs([Blob.new(contents:, sha256:, size: contents.size)]).sole
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

    version.metadata_blob = import_blobs([metadata_blob]).sole

    unless version.quick_spec_blob.present?
      resp = Faraday.get("#{version.server.url}/quick/Marshal.4.8/#{version.full_name}.gemspec.rz", nil, { "Accept" => "application/octet-stream" })
      if resp.status != 200
        raise "Failed to download quick spec: #{resp.status}"
      end

      contents = resp.body
      sha256 = Digest::SHA256.hexdigest(contents)
      raise "Checksum mismatch, expected: #{version.spec_sha256} got: #{sha256}" unless sha256 == version.spec_sha256
      _quick_spec_blob = Blob.create!(contents:, sha256:, size: contents.size)
    end

    {
      version:,
      metadata_blob: version.metadata_blob,
      quick_spec_blob: version.quick_spec_blob,
      entries: version.version_data_entries.joins(:blob).pluck(:id, :sha256, 'blobs.id'),
    }
  end

  private

  def read_package(version, blob)
    source_date_epoch = metadata = entries = nil

    pkg = Gem::Package.new(StringIO.new(blob.contents))
    pkg.gem.with_read_io do |io|
      reader = Gem::Package::TarReader.new io

      reader.each do |entry|
        logger.info "mismatched source_date_epoch: #{source_date_epoch} vs #{entry.header.mtime} in #{entry.full_name} in #{version.full_name}" if source_date_epoch && source_date_epoch != entry.header.mtime
        source_date_epoch = entry.header.mtime

        case entry.header.name
        when "metadata.gz"
          raise "metadata.gz already present" if metadata
          metadata = read_already_gzipped(entry)
        when "data.tar.gz"
          raise "data.tar.gz already present" if entries
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
          raise "unexpected file in gem: #{entry.header.name}"
        end
      end
    end

    return source_date_epoch, metadata, entries
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
    contents = entry.read
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
      if s.sum { _1.contents&.size || 0 } + elem.size < 50.megabytes
        s << elem
      else
        acc << [elem]
      end
      acc
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

    if blob.contents.size > 50.megabytes
      logger.warn "Blob too large to store", sha256: blob.sha256, size: blob.size
      blob.contents = nil
      blob.compression = nil
    end
  end
end
