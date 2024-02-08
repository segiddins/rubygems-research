class CreateVersionPackages < ActiveRecord::Migration[7.1]
  def change
    create_table :version_packages do |t|
      t.references :version, null: false, foreign_key: true
      t.string :sha256, index: true
      t.datetime :source_date_epoch

      t.timestamps
    end
  end
end
