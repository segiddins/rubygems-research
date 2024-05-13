# == Schema Information
#
# Table name: gem_downloads
#
#  id         :bigint           not null, primary key
#  as_of      :datetime
#  count      :bigint
#  rubygem_id :bigint           not null
#  server_id  :bigint           not null
#  version_id :bigint           not null
#
# Indexes
#
#  index_gem_downloads_on_rubygem_id  (rubygem_id)
#  index_gem_downloads_on_server_id   (server_id)
#  index_gem_downloads_on_version_id  (version_id)
#
# Foreign Keys
#
#  fk_rails_...  (rubygem_id => rubygems.id)
#  fk_rails_...  (server_id => servers.id)
#  fk_rails_...  (version_id => versions.id)
#
class GemDownload < ApplicationRecord
  belongs_to :rubygem
  belongs_to :version
  belongs_to :server
end
