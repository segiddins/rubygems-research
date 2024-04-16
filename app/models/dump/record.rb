class Dump::Record < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :dump, reading: :dump }
end
