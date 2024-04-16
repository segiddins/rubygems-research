class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  ActiveRecord::Import.require_adapter('sqlite3')
end
