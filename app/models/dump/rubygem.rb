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
class Dump::Rubygem < Dump::Record
  has_many :versions, inverse_of: :rubygem, class_name: 'Dump::Version'
  self.primary_key = :id
end
