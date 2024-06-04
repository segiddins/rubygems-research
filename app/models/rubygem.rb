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
class Rubygem < ApplicationRecord
  include MeiliSearch::Rails

  belongs_to :server
  has_many :versions, -> { by_position }
  has_many :version_data_entries, through: :versions
  has_many :package_blobs, through: :versions
  validates :name, presence: true, uniqueness: { scope: :server_id }

  meilisearch do
    filterable_attributes [:name, :server_url]
    attributes :name
    attribute :server_url do
      server.url
    end
  end

  def bulk_reorder_versions
    numbers = reload.versions.sort.reverse.map(&:number).uniq

    transaction do
      versions.each do |version|
        version.update_column :position, numbers.index(version.number)
      end
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "name", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["package_blobs", "server", "version_data_entries", "versions"]
  end

  def self.ransortable_attributes(_ = nil)
    ["name", "created_at"]
  end
end
