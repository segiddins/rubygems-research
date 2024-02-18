class CreateCompactIndexEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :compact_index_entries do |t|
      t.references :server, null: false, foreign_key: true
      t.string :path
      t.binary :contents
      t.datetime :last_modified
      t.string :etag
      t.string :sha256

      t.timestamps

      t.index %i[path server_id], unique: true
    end
  end
end
