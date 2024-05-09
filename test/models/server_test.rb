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
require "test_helper"

class ServerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
