# == Schema Information
#
# Table name: versions
#
#  id                         :bigint           not null, primary key
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
require "test_helper"

class VersionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
