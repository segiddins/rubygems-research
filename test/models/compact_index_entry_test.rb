# == Schema Information
#
# Table name: compact_index_entries
#
#  id            :bigint           not null, primary key
#  contents      :binary
#  etag          :string
#  last_modified :datetime
#  path          :string
#  sha256        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  server_id     :bigint           not null
#
# Indexes
#
#  index_compact_index_entries_on_path_and_server_id  (path,server_id) UNIQUE
#  index_compact_index_entries_on_server_id           (server_id)
#
# Foreign Keys
#
#  fk_rails_...  (server_id => servers.id)
#
require "test_helper"

class CompactIndexEntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
