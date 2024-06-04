# == Schema Information
#
# Table name: blobs
#
#  id          :bigint           not null, primary key
#  compression :string
#  contents    :binary
#  sha256      :string           not null
#  size        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_blobs_on_sha256  (sha256) UNIQUE
#
require 'rubygems/package'

class Blob < ApplicationRecord
  has_many :version_data_entries, dependent: :restrict_with_exception, inverse_of: :blob

  has_many :data_entry_versions, -> {distinct}, through: :version_data_entries, source: :version
  has_many :data_entry_rubygems, -> {distinct}, through: :data_entry_versions, source: :rubygem
  has_one :package_version, class_name: "Version", foreign_key: "sha256", primary_key: "sha256", inverse_of: :package_blob_with_contents
  has_one :quick_spec_version, class_name: "Version", foreign_key: "spec_sha256", primary_key: "sha256", inverse_of: :quick_spec_blob
  has_one :package_spec_version, class_name: "Version", inverse_of: :metadata_blob, foreign_key: "metadata_blob_id"

  validates :size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: false

  scope :excluding_contents, -> { select(column_names - ["contents"]) }

  def decompressed_contents
    unless contents.nil?
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
      gem = package_spec_version.package_blob.decompressed_contents
      package = Gem::Package.new StringIO.new gem
      contents = package.gem.with_read_io do |io|
        Zlib.gunzip Gem::Package::TarReader.new(io).seek("metadata.gz", &:read)
      end
      raise "No contents for blob #{sha256} (.gemspec for #{package_spec_version.full_name})" unless contents
      if Digest::SHA256.hexdigest(contents) != sha256
        raise "SHA256 mismatch for #{package_spec_version.full_name}: expected #{sha256}, got #{Digest::SHA256.hexdigest(contents)}"
      end
      return contents
    elsif (entry = version_data_entries.includes(version: :package_blob).strict_loading.first)
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

  def self.ransackable_attributes(_ = nil)
    %w[sha256 size compression]
  end
end
