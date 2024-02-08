class AddUploadedAtToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :uploaded_at, :datetime
    add_index :versions, :uploaded_at
  end
end
