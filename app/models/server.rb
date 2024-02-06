class Server < ApplicationRecord
  has_many :rubygems
  has_many :versions, through: :rubygems
end
