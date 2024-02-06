class CreateVersionDataEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :version_data_entries do |t|
      t.belongs_to :version, null: false, foreign_key: true
      t.belongs_to :blob, null: false, foreign_key: true
      t.string :full_name
      t.string :name
      t.integer :mode
      t.integer :uid
      t.integer :gid
      t.datetime :mtime
      t.string :linkname

      t.timestamps
    end
  end
end
