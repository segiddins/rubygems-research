class CreateGemDownloads < ActiveRecord::Migration[7.1]
  def change
    create_table :gem_downloads do |t|
      t.references :rubygem, null: false, foreign_key: true
      t.references :version, null: false, foreign_key: true
      t.references :server, null: false, foreign_key: true
      t.bigint :count
      t.timestamp :as_of
    end
  end
end
