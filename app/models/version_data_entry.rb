# == Schema Information
#
# Table name: version_data_entries
#
#  id         :bigint           not null, primary key
#  full_name  :string
#  gid        :integer
#  linkname   :string
#  mode       :integer
#  mtime      :datetime
#  name       :string
#  uid        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  blob_id    :bigint
#  version_id :bigint           not null
#
# Indexes
#
#  index_version_data_entries_on_blob_id                   (blob_id)
#  index_version_data_entries_on_full_name_and_version_id  (full_name,version_id) UNIQUE
#  index_version_data_entries_on_version_id                (version_id)
#
# Foreign Keys
#
#  fk_rails_...  (blob_id => blobs.id)
#  fk_rails_...  (version_id => versions.id)
#
class VersionDataEntry < ApplicationRecord
  include MeiliSearch::Rails

  belongs_to :version
  has_one :rubygem, through: :version
  has_one :server, through: :rubygem
  belongs_to :blob, optional: true, strict_loading: true
  belongs_to :blob_excluding_contents, -> { excluding_contents }, optional: true, foreign_key: :blob_id, class_name: "Blob"

  delegate :name, to: :rubygem, prefix: true
  delegate :number, :platform, :full_name, :position, to: :version, prefix: true

  scope :meilisearch_import, -> { includes(:version, :rubygem) }
  meilisearch do
    attributes :name, :full_name, :rubygem_name, :version_number, :version_platform, :version_position, :version_full_name
  end

  trigger.after(:insert) do
    "UPDATE versions SET version_data_entries_count = version_data_entries_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = NEW.version_id;"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["full_name", "gid", "linkname", "mode", "mtime", "name", "uid"] + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    ["blob_excluding_contents", "rubygem", "version", "server"]
  end
end
