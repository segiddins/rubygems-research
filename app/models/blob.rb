require 'rubygems/package'

class Blob < ApplicationRecord
  has_many :version_data_entries, dependent: :restrict_with_exception

  has_many :data_entry_versions, through: :version_data_entries
  has_one :package_version, class_name: "Version", foreign_key: "sha256", primary_key: "sha256"
  has_one :quick_spec_version, class_name: "Version", foreign_key: "spec_sha256", primary_key: "sha256"
  has_one :package_spec_version, class_name: "Version", inverse_of: :metadata_blob

  validates :size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: false


  scope :excluding_contents, -> { select(column_names - ["contents"]) }

  def decompressed_contents
    if contents?
      return \
        case compression
        when nil
          contents
        when "gzip"
          Zlib.gunzip(contents)
        else
          raise "Unknown compression type: #{compression.inspect}"
        end
    end

    if package_version
      path = "/Users/segiddins/Development/github.com/akr/gem-codesearch/mirror/gems/#{package_version.full_name}.gem"
      if File.file? path
        contents = Gem.read_binary(path)
        if Digest::SHA256.hexdigest(contents) != sha256
          raise "SHA256 mismatch for #{package_version.full_name}: expected #{sha256}, got #{Digest::SHA256.hexdigest(contents)}"
        end
        return contents
      end
      raise "No contents for blob #{sha256} (.gem for #{package_version.full_name})"
    elsif quick_spec_version
      raise "No contents for blob #{sha256} (.gemspec.rz for #{quick_spec_version.full_name})"
    elsif package_spec_version
      raise "No contents for blob #{sha256} (.gemspec for #{package_spec_version.full_name})"
    elsif version_data_entries.any?
      entry = version_data_entries.first
      package = Gem::Package.new StringIO.new entry.version.package_blob.decompressed_contents
      contents = GemPackageEnumerator.new(package).filter_map do |e|
        e.read if e.full_name == entry.full_name
      end.first || raise("No #{entry.full_name} in #{entry.version.full_name} (#{entry.version.package_blob.sha256})")
      if Digest::SHA256.hexdigest(contents) != sha256
        raise "SHA256 mismatch for #{entry.version.full_name}: expected #{sha256}, got #{Digest::SHA256.hexdigest(contents)}"
      end
      contents
    else
      raise "No contents for blob #{sha256}"
    end
  end
end
