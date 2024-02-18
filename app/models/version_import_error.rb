# == Schema Information
#
# Table name: version_import_errors
#
#  id         :integer          not null, primary key
#  error      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  version_id :integer          not null
#
# Indexes
#
#  index_version_import_errors_on_error       (error)
#  index_version_import_errors_on_version_id  (version_id) UNIQUE
#
# Foreign Keys
#
#  version_id  (version_id => versions.id)
#
class VersionImportError < ApplicationRecord
  belongs_to :version
end
