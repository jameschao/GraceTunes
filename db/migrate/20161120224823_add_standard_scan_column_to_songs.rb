class AddStandardScanColumnToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :standard_scan, :text
  end
end
