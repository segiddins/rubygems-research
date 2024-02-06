class IndexVersionsOnSha256AndSpecSha256 < ActiveRecord::Migration[7.1]
  def change
    add_index :versions, :sha256
    add_index :versions, :spec_sha256
  end
end
