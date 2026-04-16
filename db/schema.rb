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

ActiveRecord::Schema[7.2].define(version: 2026_04_16_000700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"

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
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "trailer_url"
    t.boolean "available", default: true
    t.boolean "premium", default: false
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
    t.index ["slug"], name: "index_custom_pages_on_slug", unique: true
  end

  create_table "episodes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.bigint "season_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.string "thumbnail"
    t.float "skip_intro_start"
    t.float "skip_intro_end"
    t.float "episode_end"
    t.boolean "premium", default: false
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

  create_table "live_tv_channels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "logo_url"
    t.string "stream_url", null: false
    t.string "stream_format", default: "hls", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "position", default: 0
    t.string "xmltv_channel_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_live_tv_channels_on_is_active"
    t.index ["position"], name: "index_live_tv_channels_on_position"
    t.index ["xmltv_channel_id"], name: "index_live_tv_channels_on_xmltv_channel_id"
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id", null: false
    t.uuid "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_device_grants", force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "device_code", null: false
    t.string "user_code"
    t.integer "expires_in", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_polling_at", precision: nil
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_device_grants_on_application_id"
    t.index ["device_code"], name: "index_oauth_device_grants_on_device_code", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_device_grants_on_resource_owner_id"
    t.index ["user_code"], name: "index_oauth_device_grants_on_user_code", unique: true
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

  create_table "subscription_payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.bigint "user_subscription_id", null: false
    t.string "provider", null: false
    t.string "provider_payment_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", null: false
    t.string "status", null: false
    t.datetime "paid_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_payment_id"], name: "index_subscription_payments_on_provider_and_provider_payment_id", unique: true
    t.index ["user_id"], name: "index_subscription_payments_on_user_id"
    t.index ["user_subscription_id"], name: "index_subscription_payments_on_user_subscription_id"
  end

  create_table "tv_programs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "live_tv_channel_id", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "icon_url"
    t.string "category"
    t.string "xmltv_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_time"], name: "index_tv_programs_on_end_time"
    t.index ["live_tv_channel_id", "start_time", "end_time"], name: "index_tv_programs_on_channel_and_times"
    t.index ["live_tv_channel_id"], name: "index_tv_programs_on_live_tv_channel_id"
    t.index ["start_time"], name: "index_tv_programs_on_start_time"
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
    t.string "provider", default: "mercado_pago", null: false
    t.string "provider_subscription_id"
    t.string "provider_customer_id"
    t.string "provider_plan_id"
    t.string "checkout_reference"
    t.string "external_status"
    t.boolean "granted_by_admin", default: false, null: false
    t.datetime "granted_until"
    t.datetime "cancelled_at"
    t.jsonb "metadata", default: {}, null: false
    t.index ["provider", "provider_subscription_id"], name: "idx_user_subscriptions_provider_external_id", unique: true, where: "(provider_subscription_id IS NOT NULL)"
    t.index ["provider"], name: "index_user_subscriptions_on_provider"
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
    t.string "status"
    t.string "temp_path"
    t.datetime "last_checked_at"
    t.string "media_status", default: "verified"
    t.integer "failure_count", default: 0
    t.index ["last_checked_at"], name: "index_video_sources_on_last_checked_at"
    t.index ["media_status"], name: "index_video_sources_on_media_status"
    t.index ["videoable_type", "videoable_id"], name: "index_video_sources_on_videoable"
  end

  create_table "watch_party_session_users", force: :cascade do |t|
    t.bigint "watch_party_session_id", null: false
    t.uuid "user_id", null: false
    t.boolean "is_host", default: false
    t.datetime "joined_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "idx_watch_party_session_users_on_user_id"
    t.index ["watch_party_session_id", "user_id"], name: "idx_watch_party_session_users_on_session_and_user", unique: true
    t.index ["watch_party_session_id"], name: "idx_watch_party_session_users_on_watch_party_session_id"
  end

  create_table "watch_party_sessions", force: :cascade do |t|
    t.string "content_id", null: false
    t.uuid "host_id", null: false
    t.uuid "user_id", null: false
    t.float "playback_current_time", default: 0.0
    t.boolean "is_playing", default: false
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.datetime "last_sync_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["content_id"], name: "idx_watch_party_sessions_on_content_id"
    t.index ["host_id"], name: "idx_watch_party_sessions_on_host_id"
    t.index ["user_id"], name: "idx_watch_party_sessions_on_user_id"
  end

  create_table "webhook_logs", force: :cascade do |t|
    t.string "event_name"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xmltv_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_fetched_at"
    t.datetime "last_parsed_at"
    t.text "raw_xml"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_xmltv_sources_on_is_active"
    t.index ["url"], name: "index_xmltv_sources_on_url", unique: true
  end

  add_foreign_key "continue_watchings", "contents"
  add_foreign_key "continue_watchings", "episodes"
  add_foreign_key "continue_watchings", "profiles"
  add_foreign_key "episodes", "seasons"
  add_foreign_key "likes", "contents"
  add_foreign_key "likes", "profiles"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_device_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_device_grants", "users", column: "resource_owner_id"
  add_foreign_key "preferences", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "reproductions", "contents"
  add_foreign_key "reproductions", "profiles"
  add_foreign_key "seasons", "contents"
  add_foreign_key "subscription_payments", "user_subscriptions"
  add_foreign_key "subscription_payments", "users"
  add_foreign_key "tv_programs", "live_tv_channels"
  add_foreign_key "watch_party_session_users", "users", name: "fk_watch_party_session_users_user"
  add_foreign_key "watch_party_session_users", "watch_party_sessions", name: "fk_watch_party_session_users_session"
  add_foreign_key "watch_party_sessions", "users", column: "host_id", name: "fk_watch_party_sessions_host"
  add_foreign_key "watch_party_sessions", "users", name: "fk_watch_party_sessions_user"
end
