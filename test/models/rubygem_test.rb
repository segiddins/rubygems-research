# == Schema Information
#
# Table name: rubygems
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  server_id  :integer          not null
#
# Indexes
#
#  index_rubygems_on_server_id           (server_id)
#  index_rubygems_on_server_id_and_name  (server_id,name) UNIQUE
#
# Foreign Keys
#
#  server_id  (server_id => servers.id)
#
require "test_helper"

class RubygemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
