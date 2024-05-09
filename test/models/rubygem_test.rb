# == Schema Information
#
# Table name: rubygems
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  server_id  :bigint           not null
#
# Indexes
#
#  index_rubygems_on_server_id_and_name  (server_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (server_id => servers.id)
#
require "test_helper"

class RubygemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
