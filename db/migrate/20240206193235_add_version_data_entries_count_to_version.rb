class AddVersionDataEntriesCountToVersion < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :version_data_entries_count, :integer, default: 0
  end
end
