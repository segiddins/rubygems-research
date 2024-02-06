class Rubygem < ApplicationRecord
  belongs_to :server
  has_many :versions, -> { by_position }
  has_many :version_data_entries, through: :versions
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
