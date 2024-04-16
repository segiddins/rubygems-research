# == Schema Information
#
# Table name: versions
#
#  id                        :integer          not null
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
class Dump::Version < Dump::Record
  belongs_to :rubygem, class_name: 'Dump::Rubygem'
end
