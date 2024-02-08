class CreateVersionGemspecs < ActiveRecord::Migration[7.1]
  def change
    create_table :version_gemspecs do |t|
      t.references :version, null: false, foreign_key: true
      t.string :sha256, index: true

      t.timestamps
    end
  end
end
