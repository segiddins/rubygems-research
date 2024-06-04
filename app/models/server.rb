# == Schema Information
#
# Table name: servers
#
#  id         :bigint           not null, primary key
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

  def self.ransackable_attributes(auth_object = nil)
    %w[
      url
    ]
  end
end
