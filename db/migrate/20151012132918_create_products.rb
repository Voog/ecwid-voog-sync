class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :voog_element_id, index: true
      t.string :ecwid_id, index: true
      t.string :ecwid_catrgory_id, index: true
      t.boolean :enabled, default: false
      t.datetime :ecwid_synced_at
      t.datetime :voog_synced_at
      # t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
