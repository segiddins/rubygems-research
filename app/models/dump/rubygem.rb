# == Schema Information
#
# Table name: rubygems
#
#  id         :integer          not null, primary key
#  indexed    :boolean          default(FALSE), not null
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  dashunderscore_typos_idx   (regexp_replace(upper((name)::text), '[_-]'::text, ''::text, 'g'::text))
#  index_rubygems_on_indexed  (indexed)
#  index_rubygems_on_name     (name) UNIQUE
#  index_rubygems_upcase      (upper((name)::text) varchar_pattern_ops)
#
class Dump::Rubygem < Dump::Record
  has_many :versions, inverse_of: :rubygem, class_name: 'Dump::Version'
  has_many :gem_downloads, inverse_of: :rubygem, class_name: 'Dump::GemDownload'
  self.primary_key = :id
end
