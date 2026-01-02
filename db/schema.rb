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

ActiveRecord::Schema.define(version: 20160821214902) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "fence_alerts", force: :cascade do |t|
    t.integer  "geofence_id"
    t.integer  "fence_state_id"
    t.string   "webhook_url"
    t.integer  "num_tries",       default: 0
    t.datetime "sent_at"
    t.integer  "response_code"
    t.text     "response"
    t.integer  "processed_stage", default: 0
    t.text     "info"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["fence_state_id"], name: "index_fence_alerts_on_fence_state_id", using: :btree
    t.index ["geofence_id"], name: "index_fence_alerts_on_geofence_id", using: :btree
    t.index ["response_code"], name: "index_fence_alerts_on_response_code", using: :btree
    t.index ["sent_at"], name: "index_fence_alerts_on_sent_at", using: :btree
  end

  create_table "fence_states", force: :cascade do |t|
    t.integer  "geofence_id"
    t.integer  "location_msg_id"
    t.string   "state"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "esn"
    t.datetime "occurred_at"
    t.index ["esn"], name: "index_fence_states_on_esn", using: :btree
    t.index ["geofence_id"], name: "index_fence_states_on_geofence_id", using: :btree
    t.index ["location_msg_id"], name: "index_fence_states_on_location_msg_id", using: :btree
    t.index ["occurred_at"], name: "index_fence_states_on_occurred_at", using: :btree
  end

  create_table "geofences", force: :cascade do |t|
    t.string    "esn"
    t.geography "fence",           limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.text      "meta"
    t.boolean   "is_single_alert"
    t.integer   "num_alerts_sent",                                                               default: 0
    t.string    "alert_type"
    t.datetime  "deleted_at"
    t.datetime  "created_at",                                                                                null: false
    t.datetime  "updated_at",                                                                                null: false
    t.string    "webhook_url"
    t.integer   "created_by"
    t.index ["created_by"], name: "index_geofences_on_created_by", using: :btree
    t.index ["deleted_at"], name: "index_geofences_on_deleted_at", using: :btree
    t.index ["esn"], name: "index_geofences_on_esn", using: :btree
    t.index ["fence"], name: "index_geofences_on_fence", using: :gist
    t.index ["is_single_alert"], name: "index_geofences_on_is_single_alert", using: :btree
    t.index ["num_alerts_sent"], name: "index_geofences_on_num_alerts_sent", using: :btree
  end

  create_table "gl200_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_gl200_messages_on_processed_stage", using: :btree
  end

  create_table "gl300_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_gl300_messages_on_processed_stage", using: :btree
  end

  create_table "gl300ma_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_gl300ma_messages_on_processed_stage", using: :btree
  end

  create_table "gps306a_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_gps306a_messages_on_processed_stage", using: :btree
  end

  create_table "info_msgs", force: :cascade do |t|
    t.string   "esn"
    t.datetime "occurred_at"
    t.string   "source"
    t.string   "value"
    t.json     "meta"
    t.string   "message_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["esn"], name: "index_info_msgs_on_esn", using: :btree
    t.index ["message_id"], name: "index_info_msgs_on_message_id", unique: true, using: :btree
    t.index ["occurred_at"], name: "index_info_msgs_on_occurred_at", using: :btree
    t.index ["source"], name: "index_info_msgs_on_source", using: :btree
    t.index ["value"], name: "index_info_msgs_on_value", using: :btree
  end

  create_table "location_msgs", force: :cascade do |t|
    t.string    "esn"
    t.datetime  "occurred_at"
    t.geography "point",       limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.json      "meta"
    t.string    "message_id"
    t.datetime  "created_at",                                                              null: false
    t.datetime  "updated_at",                                                              null: false
    t.index ["esn"], name: "index_location_msgs_on_esn", using: :btree
    t.index ["message_id"], name: "index_location_msgs_on_message_id", unique: true, using: :btree
    t.index ["occurred_at"], name: "index_location_msgs_on_occurred_at", using: :btree
    t.index ["point"], name: "index_location_msgs_on_point", using: :gist
  end

  create_table "parsed_messages", force: :cascade do |t|
    t.string   "origin_message_type"
    t.integer  "origin_message_id"
    t.string   "esn"
    t.string   "source"
    t.string   "value"
    t.string   "meta"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.datetime "occurred_at"
    t.boolean  "is_sent",             default: false
    t.text     "info"
    t.integer  "num_tries",           default: 0
    t.string   "message_id"
  end

  create_table "prv_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "processed_stage", default: 0
  end

  create_table "settings", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", using: :btree
  end

  create_table "smart_bdgps_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_smart_bdgps_messages_on_processed_stage", using: :btree
  end

  create_table "spot_trace_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_spot_trace_messages_on_processed_stage", using: :btree
  end

  create_table "stu_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "processed_stage", default: 0
  end

  create_table "xexun_tk1022_messages", force: :cascade do |t|
    t.text     "raw"
    t.string   "status"
    t.text     "extra"
    t.integer  "processed_stage", default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["processed_stage"], name: "index_xexun_tk1022_messages_on_processed_stage", using: :btree
  end

  add_foreign_key "fence_alerts", "fence_states"
  add_foreign_key "fence_alerts", "geofences"
  add_foreign_key "fence_states", "geofences"
  add_foreign_key "fence_states", "location_msgs"
end
