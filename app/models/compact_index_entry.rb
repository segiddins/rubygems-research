# == Schema Information
#
# Table name: compact_index_entries
#
#  id            :integer          not null, primary key
#  contents      :binary
#  etag          :string
#  last_modified :datetime
#  path          :string
#  sha256        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  server_id     :integer          not null
#
# Indexes
#
#  index_compact_index_entries_on_path_and_server_id  (path,server_id) UNIQUE
#  index_compact_index_entries_on_server_id           (server_id)
#
# Foreign Keys
#
#  server_id  (server_id => servers.id)
#
class CompactIndexEntry < ApplicationRecord
  belongs_to :server

  def decompressed_contents
    return if contents.nil?
    Zlib.gunzip(contents)
  end
end
