# == Schema Information
#
# Table name: blobs
#
#  id          :integer          not null, primary key
#  compression :string
#  contents    :binary
#  sha256      :string           not null
#  size        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_blobs_on_sha256  (sha256) UNIQUE
#
require "test_helper"

class BlobTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
