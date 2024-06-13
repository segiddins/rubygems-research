class RemoveSha256FromVersionDataEntries < ActiveRecord::Migration[7.1]
  def change
    remove_index :version_data_entries, name: "index_version_data_entries_on_sha256"
    remove_column :version_data_entries, :sha256, :string
  end
end
