class AddSha256ToVersionDataEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :version_data_entries, :sha256, :string
    add_index :version_data_entries, :sha256
  end
end
