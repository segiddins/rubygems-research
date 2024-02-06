class VersionDataEntry < ApplicationRecord
  belongs_to :version
  belongs_to :blob, optional: true
end
