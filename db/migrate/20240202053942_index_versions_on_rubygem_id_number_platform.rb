class IndexVersionsOnRubygemIdNumberPlatform < ActiveRecord::Migration[7.1]
  def change
    add_index :versions, [:rubygem_id, :number, :platform], unique: true
  end
end
