class RenameEcwidCatrgoryIdInProduct < ActiveRecord::Migration
  def up
    remove_index(:products, :ecwid_catrgory_id)
    rename_column(:products, :ecwid_catrgory_id, :ecwid_category_id)
    add_index(:products, :ecwid_category_id)
  end

  def down
    remove_index(:products, :ecwid_category_id)
    rename_column(:products, :ecwid_category_id, :ecwid_catrgory_id)
    add_index(:products, :ecwid_catrgory_id)
  end
end
