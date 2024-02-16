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
class Rubygem < ApplicationRecord
  belongs_to :server
  has_many :versions, -> { by_position }
  has_many :version_data_entries, through: :versions
  has_many :package_blobs, through: :versions
  validates :name, presence: true, uniqueness: { scope: :server_id }

  def bulk_reorder_versions
    numbers = reload.versions.sort.reverse.map(&:number).uniq

    transaction do
      versions.each do |version|
        version.update_column :position, numbers.index(version.number)
      end
    end
  end
end
