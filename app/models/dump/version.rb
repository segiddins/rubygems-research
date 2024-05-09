# == Schema Information
#
# Table name: versions
#
#  id                        :integer          not null, primary key
#  authors                   :text
#  built_at                  :datetime
#  canonical_number          :string
#  cert_chain                :text
#  description               :text
#  full_name                 :string(255)
#  gem_full_name             :string
#  gem_platform              :string
#  indexed                   :boolean          default(TRUE)
#  info_checksum             :string
#  latest                    :boolean
#  licenses                  :string(255)
#  metadata                  :hstore           not null
#  number                    :string(255)
#  platform                  :string(255)
#  position                  :integer
#  prerelease                :boolean
#  required_ruby_version     :string(255)
#  required_rubygems_version :string(255)
#  requirements              :text
#  sha256                    :string(255)
#  size                      :integer
#  spec_sha256               :string(44)
#  summary                   :text
#  yanked_at                 :datetime
#  yanked_info_checksum      :string
#  created_at                :datetime
#  updated_at                :datetime
#  pusher_api_key_id         :bigint
#  pusher_id                 :bigint
#  rubygem_id                :integer
#
# Indexes
#
#  index_versions_on_built_at                                      (built_at)
#  index_versions_on_canonical_number_and_rubygem_id_and_platform  (canonical_number,rubygem_id,platform) UNIQUE
#  index_versions_on_created_at                                    (created_at)
#  index_versions_on_full_name                                     (full_name)
#  index_versions_on_indexed_and_yanked_at                         (indexed,yanked_at)
#  index_versions_on_lower_full_name                               (lower((full_name)::text))
#  index_versions_on_lower_gem_full_name                           (lower((gem_full_name)::text))
#  index_versions_on_number                                        (number)
#  index_versions_on_position_and_rubygem_id                       (position,rubygem_id)
#  index_versions_on_prerelease                                    (prerelease)
#  index_versions_on_pusher_api_key_id                             (pusher_api_key_id)
#  index_versions_on_pusher_id                                     (pusher_id)
#  index_versions_on_rubygem_id_and_number_and_platform            (rubygem_id,number,platform) UNIQUE
#
class Dump::Version < Dump::Record
  belongs_to :rubygem, class_name: 'Dump::Rubygem'
  has_one :gem_download, class_name: 'Dump::GemDownload', inverse_of: :version
end
