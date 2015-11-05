class AddMetainfoToProduct < ActiveRecord::Migration
  def change
    add_column :products, :metainfo, :text
  end
end
