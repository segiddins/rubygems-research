class IndexServersOnUrl < ActiveRecord::Migration[7.1]
  def change
    add_index :servers, :url, unique: true
  end
end
