class AddExtensionsToVersions < ActiveRecord::Migration[7.1]
  def change
    change_table :versions, bulk: true do |t|
      t.boolean :has_extensions, null: true
      t.string :extensions, array: true, null: true
    end
  end
end
