class CreateBlobs < ActiveRecord::Migration[7.1]
  def change
    create_table :blobs do |t|
      t.string :sha256, null: false, index: {unique: true}
      t.binary :contents, null: true
      t.integer :size, null: true
      t.string :compression, null: true

      t.timestamps
    end
  end
end
