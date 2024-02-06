class AddMetadataBlobToVersions < ActiveRecord::Migration[7.1]
  def change
    add_reference :versions, :metadata_blob, null: true, foreign_key: { to_table: :blobs }
  end
end
