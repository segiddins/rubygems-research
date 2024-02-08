# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerVersionDataEntriesInsert < ActiveRecord::Migration[7.1]
  def up
    create_trigger("version_data_entries_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("version_data_entries").
        after(:insert) do
      "UPDATE versions SET version_data_entries_count = version_data_entries_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = NEW.version_id;"
    end
  end

  def down
    drop_trigger("version_data_entries_after_insert_row_tr", "version_data_entries", :generated => true)
  end
end
