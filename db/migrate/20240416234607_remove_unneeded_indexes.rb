class RemoveUnneededIndexes < ActiveRecord::Migration[7.1]
  def change
    remove_index :rubygems, name: "index_rubygems_on_server_id", column: :server_id
    remove_index :versions, name: "index_versions_on_rubygem_id", column: :rubygem_id
  end
end
