class ChangeVersionDataEntryBlobToNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :version_data_entries, :blob_id, true
  end
end
