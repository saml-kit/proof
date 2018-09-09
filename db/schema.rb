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

ActiveRecord::Schema.define(version: 2018_09_09_173139) do

  create_table "authorizations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "client_id"
    t.string "code", null: false
    t.datetime "expired_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_authorizations_on_client_id"
    t.index ["code"], name: "index_authorizations_on_code"
    t.index ["user_id"], name: "index_authorizations_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "name", null: false
    t.string "secret", null: false
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_clients_on_uuid"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "uuid"
    t.string "subject_type"
    t.integer "subject_id"
    t.string "audience_type"
    t.integer "audience_id"
    t.integer "token_type", default: 0
    t.datetime "expired_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audience_type", "audience_id"], name: "index_tokens_on_audience_type_and_audience_id"
    t.index ["subject_type", "subject_id"], name: "index_tokens_on_subject_type_and_subject_id"
    t.index ["uuid"], name: "index_tokens_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "uuid", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "mfa_secret", limit: 16
    t.index ["uuid"], name: "index_users_on_uuid"
  end

end
