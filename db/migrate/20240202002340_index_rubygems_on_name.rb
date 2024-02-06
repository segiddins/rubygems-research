class IndexRubygemsOnName < ActiveRecord::Migration[7.1]
  def change
    add_index :rubygems, %i[server_id name], unique: true
  end
end
