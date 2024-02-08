class VersionDataEntry < ApplicationRecord
  belongs_to :version
  belongs_to :blob, optional: true

  trigger.after(:insert) do
    "UPDATE versions SET version_data_entries_count = version_data_entries_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = NEW.version_id;"
  end
end
