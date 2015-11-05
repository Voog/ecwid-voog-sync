class AddMetainfoToCategory < ActiveRecord::Migration
  def change
    add_column :categories, :metainfo, :text
  end
end
