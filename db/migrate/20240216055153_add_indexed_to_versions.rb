class AddIndexedToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :indexed, :boolean, default: true
  end
end
