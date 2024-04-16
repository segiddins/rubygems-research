# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_04_15_205636) do
  create_table "blobs", force: :cascade do |t|
    t.string "sha256", null: false
    t.binary "contents"
    t.integer "size"
    t.string "compression"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha256"], name: "index_blobs_on_sha256", unique: true
  end

  create_table "compact_index_entries", force: :cascade do |t|
    t.integer "server_id", null: false
    t.string "path"
    t.binary "contents"
    t.datetime "last_modified"
    t.string "etag"
    t.string "sha256"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path", "server_id"], name: "index_compact_index_entries_on_path_and_server_id", unique: true
    t.index ["server_id"], name: "index_compact_index_entries_on_server_id"
  end

  create_table "maintenance_tasks_runs", force: :cascade do |t|
    t.string "task_name", null: false
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.float "time_running", default: 0.0, null: false
    t.bigint "tick_count"
    t.bigint "tick_total"
    t.string "job_id"
    t.string "cursor"
    t.string "status", default: "enqueued", null: false
    t.string "error_class"
    t.string "error_message"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "arguments"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "rubygems", force: :cascade do |t|
    t.integer "server_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id", "name"], name: "index_rubygems_on_server_id_and_name", unique: true
    t.index ["server_id"], name: "index_rubygems_on_server_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_servers_on_url", unique: true
  end

  create_table "version_data_entries", force: :cascade do |t|
    t.integer "version_id", null: false
    t.integer "blob_id"
    t.string "full_name"
    t.string "name"
    t.integer "mode"
    t.integer "uid"
    t.integer "gid"
    t.datetime "mtime"
    t.string "linkname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sha256"
    t.index ["blob_id"], name: "index_version_data_entries_on_blob_id"
    t.index ["full_name", "version_id"], name: "index_version_data_entries_on_full_name_and_version_id", unique: true
    t.index ["sha256"], name: "index_version_data_entries_on_sha256"
    t.index ["version_id"], name: "index_version_data_entries_on_version_id"
  end

  create_table "version_gemspecs", force: :cascade do |t|
    t.integer "version_id", null: false
    t.string "sha256"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha256"], name: "index_version_gemspecs_on_sha256"
    t.index ["version_id"], name: "index_version_gemspecs_on_version_id"
  end

  create_table "version_import_errors", force: :cascade do |t|
    t.integer "version_id", null: false
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["error"], name: "index_version_import_errors_on_error"
    t.index ["version_id"], name: "index_version_import_errors_on_version_id", unique: true
  end

  create_table "version_packages", force: :cascade do |t|
    t.integer "version_id", null: false
    t.string "sha256"
    t.datetime "source_date_epoch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha256"], name: "index_version_packages_on_sha256"
    t.index ["version_id"], name: "index_version_packages_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.integer "rubygem_id", null: false
    t.string "number"
    t.string "platform"
    t.string "spec_sha256"
    t.string "sha256"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "metadata_blob_id"
    t.integer "position"
    t.integer "version_data_entries_count", default: 0
    t.datetime "uploaded_at"
    t.boolean "indexed", default: true
    t.index ["metadata_blob_id"], name: "index_versions_on_metadata_blob_id"
    t.index ["rubygem_id", "number", "platform"], name: "index_versions_on_rubygem_id_and_number_and_platform", unique: true
    t.index ["rubygem_id"], name: "index_versions_on_rubygem_id"
    t.index ["sha256"], name: "index_versions_on_sha256"
    t.index ["spec_sha256"], name: "index_versions_on_spec_sha256"
    t.index ["uploaded_at"], name: "index_versions_on_uploaded_at"
  end

  add_foreign_key "compact_index_entries", "servers"
  add_foreign_key "rubygems", "servers"
  add_foreign_key "version_data_entries", "blobs"
  add_foreign_key "version_data_entries", "versions"
  add_foreign_key "version_gemspecs", "versions"
  add_foreign_key "version_import_errors", "versions"
  add_foreign_key "version_packages", "versions"
  add_foreign_key "versions", "blobs", column: "metadata_blob_id"
  add_foreign_key "versions", "rubygems"
  create_trigger("version_data_entries_after_insert_row_tr", :generated => true, :compatibility => 1).
      on("version_data_entries").
      after(:insert) do
    "UPDATE versions SET version_data_entries_count = version_data_entries_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = NEW.version_id;"
  end

end
