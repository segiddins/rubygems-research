class Version < ApplicationRecord
  belongs_to :rubygem
  has_one :server, through: :rubygem
  belongs_to :metadata_blob, class_name: "Blob", optional: true, dependent: :destroy
  has_one :package_blob, class_name: "Blob", dependent: :destroy, inverse_of: :package_version, foreign_key: "sha256", primary_key: "sha256"
  has_one :quick_spec_blob, class_name: "Blob", dependent: :destroy, inverse_of: :quick_spec_version, foreign_key: "sha256", primary_key: "spec_sha256"
  has_many :version_data_entries
  has_many :data_blobs, through: :version_data_entries, source: :blob
  validates :number, presence: true, uniqueness: { scope: %i[rubygem_id platform] }
  validates :platform, presence: true

  def self.by_position
    order(:position)
  end

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

  def <=>(other)
    [to_gem_version, platform_as_number, platform] <=> [other.to_gem_version, other.platform_as_number, other.platform]
  end
end
