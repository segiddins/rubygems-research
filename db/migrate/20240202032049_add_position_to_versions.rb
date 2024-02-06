class AddPositionToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :position, :integer
  end
end
