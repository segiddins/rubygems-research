# == Schema Information
#
# Table name: version_data_entries
#
#  id         :integer          not null, primary key
#  full_name  :string
#  gid        :integer
#  linkname   :string
#  mode       :integer
#  mtime      :datetime
#  name       :string
#  sha256     :string
#  uid        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  blob_id    :integer
#  version_id :integer          not null
#
# Indexes
#
#  index_version_data_entries_on_blob_id                   (blob_id)
#  index_version_data_entries_on_full_name_and_version_id  (full_name,version_id) UNIQUE
#  index_version_data_entries_on_sha256                    (sha256)
#  index_version_data_entries_on_version_id                (version_id)
#
# Foreign Keys
#
#  blob_id     (blob_id => blobs.id)
#  version_id  (version_id => versions.id)
#
class VersionDataEntry < ApplicationRecord
  belongs_to :version
  has_one :rubygem, through: :version
  belongs_to :blob, optional: true, strict_loading: true
  belongs_to :blob_excluding_contents, -> { excluding_contents }, optional: true, foreign_key: :blob_id, class_name: "Blob"

  trigger.after(:insert) do
    "UPDATE versions SET version_data_entries_count = version_data_entries_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = NEW.version_id;"
  end
end
