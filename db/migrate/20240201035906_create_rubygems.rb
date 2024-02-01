class CreateRubygems < ActiveRecord::Migration[7.1]
  def change
    create_table :rubygems do |t|
      t.belongs_to :server, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
