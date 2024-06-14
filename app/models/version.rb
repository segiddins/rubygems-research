# == Schema Information
#
# Table name: versions
#
#  id                         :bigint           not null, primary key
#  extensions                 :string           is an Array
#  has_extensions             :boolean
#  indexed                    :boolean          default(TRUE)
#  metadata                   :json
#  number                     :string
#  platform                   :string
#  position                   :integer
#  sha256                     :string
#  spec_sha256                :string
#  uploaded_at                :datetime
#  version_data_entries_count :integer          default(0)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  metadata_blob_id           :bigint
#  rubygem_id                 :bigint           not null
#
# Indexes
#
#  index_versions_on_metadata_blob_id                    (metadata_blob_id)
#  index_versions_on_rubygem_id_and_number_and_platform  (rubygem_id,number,platform) UNIQUE
#  index_versions_on_sha256                              (sha256)
#  index_versions_on_spec_sha256                         (spec_sha256)
#  index_versions_on_uploaded_at                         (uploaded_at)
#
# Foreign Keys
#
#  fk_rails_...  (metadata_blob_id => blobs.id)
#  fk_rails_...  (rubygem_id => rubygems.id)
#
class Version < ApplicationRecord
  belongs_to :rubygem
  has_one :server, through: :rubygem
  belongs_to :metadata_blob, class_name: "Blob", optional: true, dependent: :destroy, strict_loading: true
  has_one :package_blob, -> { excluding_contents }, class_name: "Blob", dependent: :destroy, inverse_of: :package_version, foreign_key: "sha256", primary_key: "sha256"
  has_one :package_blob_with_contents, class_name: "Blob", dependent: :destroy, inverse_of: :package_version, foreign_key: "sha256", primary_key: "sha256"
  has_one :quick_spec_blob, -> { excluding_contents }, class_name: "Blob", dependent: :destroy, inverse_of: :quick_spec_version, foreign_key: "sha256", primary_key: "spec_sha256"
  has_many :version_data_entries, strict_loading: true
  has_many :data_blobs, through: :version_data_entries, source: :blob, strict_loading: true
  has_one :version_import_error
  validates :number, presence: true, uniqueness: { scope: %i[rubygem_id platform] }
  validates :platform, presence: true

  def self.by_position
    order(:position)
  end

  scope :indexed, -> { where(indexed: true) }
  scope :yanked, -> { where(indexed: false) }

  def full_name
    if platformed?
      "#{rubygem.name}-#{number}-#{platform}"
    else
      "#{rubygem.name}-#{number}"
    end
  end

  def slug
    full_name.delete_prefix("#{rubygem.name}-")
  end

  def platformed? = platform.present? && platform != Gem::Platform::RUBY

  def platform_as_number
    if platformed?
      0
    else
      1
    end
  end

  def to_gem_version
    Gem::Version.new(number)
  end

  def gemspec
    yaml = metadata_blob&.decompressed_contents || raise(ActiveRecord::RecordNotFound, "metadata_blob not found for version #{id}")
    Gem::Specification.from_yaml(yaml)
  end

  def <=>(other)
    [to_gem_version, platform_as_number, platform] <=> [other.to_gem_version, other.platform_as_number, other.platform]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      indexed
      number
      platform
      position
      sha256
      spec_sha256
      uploaded_at
      version_data_entries_count
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["data_blobs", "metadata_blob", "package_blob", "package_blob_with_contents", "quick_spec_blob", "rubygem", "server", "version_data_entries", "version_import_error"]
  end

  def self.ransortable_attributes(_ = nil)
    ["uploaded_at", "version_data_entries_count"]
  end
end
