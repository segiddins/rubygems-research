class IndexVersionDataEntryOnFullNameAndVersionId < ActiveRecord::Migration[7.1]
  def change
    add_index :version_data_entries, [:full_name, :version_id], unique: true
  end
end
