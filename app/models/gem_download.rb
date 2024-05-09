class GemDownload < ApplicationRecord
  belongs_to :rubygem
  belongs_to :version
  belongs_to :server
end
