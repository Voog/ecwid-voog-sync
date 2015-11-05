# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151105144930) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "categories", force: :cascade do |t|
    t.string   "name"
    t.string   "ecwid_id"
    t.boolean  "ecwid_enabled",   default: false
    t.string   "ecwid_parent_id"
    t.datetime "ecwid_synced_at"
    t.string   "voog_page_id"
    t.boolean  "voog_enabled",    default: false
    t.datetime "voog_synced_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "metainfo"
  end

  add_index "categories", ["ecwid_id"], name: "index_categories_on_ecwid_id", using: :btree
  add_index "categories", ["ecwid_parent_id"], name: "index_categories_on_ecwid_parent_id", using: :btree
  add_index "categories", ["voog_page_id"], name: "index_categories_on_voog_page_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.string   "voog_element_id"
    t.string   "ecwid_id"
    t.string   "ecwid_category_id"
    t.boolean  "enabled",           default: false
    t.datetime "ecwid_synced_at"
    t.datetime "voog_synced_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.text     "metainfo"
  end

  add_index "products", ["ecwid_category_id"], name: "index_products_on_ecwid_category_id", using: :btree
  add_index "products", ["ecwid_id"], name: "index_products_on_ecwid_id", using: :btree
  add_index "products", ["voog_element_id"], name: "index_products_on_voog_element_id", using: :btree

end
