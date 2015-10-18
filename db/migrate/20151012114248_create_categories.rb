class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.string :ecwid_id, index: true
      t.boolean :ecwid_enabled, default: false
      t.string :ecwid_parent_id, index: true
      t.datetime :ecwid_synced_at
      t.string :voog_page_id, index: true
      t.boolean :voog_enabled, default: false
      t.datetime :voog_synced_at
      # t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
