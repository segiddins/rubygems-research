# == Schema Information
#
# Table name: servers
#
#  id         :integer          not null, primary key
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_servers_on_url  (url) UNIQUE
#
class Server < ApplicationRecord
  has_many :rubygems
  has_many :versions, through: :rubygems
  has_many :compact_index_entries
end
