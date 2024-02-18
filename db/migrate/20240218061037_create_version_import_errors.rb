class CreateVersionImportErrors < ActiveRecord::Migration[7.1]
  def change
    create_table :version_import_errors do |t|
      t.references :version, null: false, foreign_key: true, index: { unique: true }
      t.string :error, index: true

      t.timestamps
    end
  end
end
