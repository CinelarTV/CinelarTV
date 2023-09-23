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

ActiveRecord::Schema[7.0].define(version: 2023_09_23_174851) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "banner"
    t.string "cover"
    t.string "content_type"
    t.string "url"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "trailer_url"
    t.boolean "available"
  end

  create_table "continue_watchings", force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "content_id", null: false
    t.uuid "episode_id"
    t.float "progress", default: 0.0, null: false
    t.float "duration", default: 0.0, null: false
    t.datetime "last_watched_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "finished", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_continue_watchings_on_content_id"
    t.index ["episode_id"], name: "index_continue_watchings_on_episode_id"
    t.index ["profile_id", "content_id", "episode_id"], name: "unique_continue_watchings_index", unique: true
    t.index ["profile_id"], name: "index_continue_watchings_on_profile_id"
  end

  create_table "custom_pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "template"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "episodes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "url"
    t.bigint "season_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.string "thumbnail"
    t.float "skip_intro_start"
    t.float "skip_intro_end"
    t.float "episode_end"
    t.index ["season_id"], name: "index_episodes_on_season_id"
  end

  create_table "likes", force: :cascade do |t|
    t.uuid "profile_id"
    t.uuid "content_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_likes_on_content_id"
    t.index ["profile_id"], name: "index_likes_on_profile_id"
  end

  create_table "preferences", force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_preferences_on_profile_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name"
    t.string "profile_type"
    t.string "avatar_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "reproductions", force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "content_id", null: false
    t.datetime "played_at", null: false
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_reproductions_on_content_id"
    t.index ["profile_id"], name: "index_reproductions_on_profile_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.uuid "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "scheduler_stats", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "hostname", null: false
    t.integer "pid", null: false
    t.integer "duration_ms"
    t.integer "live_slots_start"
    t.integer "live_slots_finish"
    t.datetime "started_at", precision: nil, null: false
    t.boolean "success"
    t.text "error"
  end

  create_table "seasons", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.uuid "content_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["content_id"], name: "index_seasons_on_content_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.string "data_type", default: "string", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "exposed_to_client", default: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "order_id"
    t.integer "order_item_id"
    t.integer "product_id"
    t.integer "variant_id"
    t.string "product_name"
    t.string "variant_name"
    t.string "user_name"
    t.string "user_email"
    t.string "status"
    t.string "status_formatted"
    t.string "card_brand"
    t.string "card_last_four"
    t.boolean "cancelled"
    t.datetime "trial_ends_at"
    t.integer "billing_anchor"
    t.datetime "renews_at"
    t.datetime "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "test_mode"
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.integer "customer_id"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.uuid "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "video_sources", force: :cascade do |t|
    t.string "url"
    t.string "quality"
    t.string "format"
    t.string "storage_location"
    t.string "videoable_type", null: false
    t.uuid "videoable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["videoable_type", "videoable_id"], name: "index_video_sources_on_videoable"
  end

  create_table "webhook_logs", force: :cascade do |t|
    t.string "event_name"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "continue_watchings", "contents"
  add_foreign_key "continue_watchings", "episodes"
  add_foreign_key "continue_watchings", "profiles"
  add_foreign_key "episodes", "seasons"
  add_foreign_key "likes", "contents"
  add_foreign_key "likes", "profiles"
  add_foreign_key "preferences", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "reproductions", "contents"
  add_foreign_key "reproductions", "profiles"
  add_foreign_key "seasons", "contents"
end
