class CreateVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :versions do |t|
      t.belongs_to :rubygem, null: false, foreign_key: true
      t.string :number
      t.string :platform
      t.string :spec_sha256
      t.string :sha256
      t.json :metadata

      t.timestamps
    end
  end
end
