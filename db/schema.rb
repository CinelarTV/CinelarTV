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

ActiveRecord::Schema[7.2].define(version: 2026_08_31_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "intarray"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "backups", force: :cascade do |t|
    t.string "filename", null: false
    t.bigint "size"
    t.string "backup_type"
    t.string "source"
    t.text "notes"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.string "checksum"
    t.boolean "encrypted", default: false, null: false
    t.text "encryption_key_fingerprint"
    t.jsonb "file_manifest", default: {}
    t.jsonb "audit_log", default: []
    t.datetime "completed_at"
    t.datetime "expires_at"
    t.integer "retention_days", default: 30
    t.string "error_message"
    t.index ["created_at"], name: "index_backups_on_created_at"
    t.index ["expires_at"], name: "index_backups_on_expires_at"
    t.index ["filename"], name: "index_backups_on_filename", unique: true
    t.index ["status"], name: "index_backups_on_status"
  end

  create_table "cast_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.uuid "person_id", null: false
    t.string "character_name"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id", "order"], name: "index_cast_members_on_content_id_and_order"
    t.index ["content_id", "person_id"], name: "index_cast_members_on_content_id_and_person_id", unique: true
    t.index ["content_id"], name: "index_cast_members_on_content_id"
    t.index ["person_id"], name: "index_cast_members_on_person_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tmdb_id"
    t.index ["tmdb_id"], name: "index_categories_on_tmdb_id", unique: true, where: "(tmdb_id IS NOT NULL)"
  end

  create_table "content_analytics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.integer "total_views", default: 0, null: false
    t.float "total_seconds_watched", default: 0.0, null: false
    t.integer "unique_profiles", default: 0, null: false
    t.float "completion_rate", default: 0.0, null: false
    t.float "avg_watch_percentage", default: 0.0, null: false
    t.datetime "last_watched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_content_analytics_on_content_id", unique: true
    t.index ["last_watched_at"], name: "index_content_analytics_on_last_watched_at"
    t.index ["total_views"], name: "index_content_analytics_on_total_views"
  end

  create_table "content_categories", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_content_categories_on_category_id"
    t.index ["content_id", "category_id"], name: "index_content_categories_on_content_id_and_category_id", unique: true
    t.index ["content_id"], name: "index_content_categories_on_content_id"
  end

  create_table "content_content_descriptors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.uuid "content_descriptor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_descriptor_id"], name: "index_content_content_descriptors_on_content_descriptor_id"
    t.index ["content_id", "content_descriptor_id"], name: "idx_ccd_on_content_and_descriptor", unique: true
    t.index ["content_id"], name: "index_content_content_descriptors_on_content_id"
  end

  create_table "content_descriptors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "name_translations", default: {}
    t.jsonb "description_translations", default: {}
    t.string "category", null: false
    t.integer "severity_level", default: 1
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_content_descriptors_on_key", unique: true
  end

  create_table "content_ratings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "system", null: false
    t.jsonb "name_translations", default: {}
    t.jsonb "description_translations", default: {}
    t.integer "min_age"
    t.string "color", default: "#ffffff"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_content_ratings_on_code", unique: true
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
    t.integer "tmdb_id"
    t.string "banner_resized"
    t.string "cover_resized"
    t.datetime "scheduled_launch_at"
    t.tsvector "search_data"
    t.uuid "content_rating_id"
    t.string "content_rating_code"
    t.index ["available"], name: "index_contents_on_available_true", where: "(available = true)"
    t.index ["content_rating_id"], name: "index_contents_on_content_rating_id"
    t.index ["content_type"], name: "index_contents_on_content_type"
    t.index ["created_at"], name: "index_contents_on_available_and_created_at", order: :desc, where: "(available = true)"
    t.index ["scheduled_launch_at"], name: "index_contents_on_scheduled_launch_pending", where: "((scheduled_launch_at IS NOT NULL) AND (available = false))"
    t.index ["search_data"], name: "index_contents_on_search_data", using: :gin
    t.index ["tmdb_id"], name: "index_contents_on_tmdb_id"
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
    t.index ["last_watched_at"], name: "index_continue_watchings_on_last_watched_at"
    t.index ["profile_id", "content_id", "episode_id"], name: "unique_continue_watchings_index", unique: true
    t.index ["profile_id", "last_watched_at"], name: "index_continue_watchings_on_profile_id_and_last_watched_at"
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

  create_table "dislikes", force: :cascade do |t|
    t.uuid "profile_id"
    t.uuid "content_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_dislikes_on_content_id"
    t.index ["profile_id"], name: "index_dislikes_on_profile_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "key", null: false
    t.string "locale", null: false
    t.text "subject"
    t.text "body"
    t.jsonb "interpolation_variables", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "locale"], name: "index_email_templates_on_key_and_locale", unique: true
    t.index ["key"], name: "index_email_templates_on_key"
    t.index ["locale"], name: "index_email_templates_on_locale"
  end

  create_table "episode_content_descriptors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "episode_id", null: false
    t.uuid "content_descriptor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_descriptor_id"], name: "index_episode_content_descriptors_on_content_descriptor_id"
    t.index ["episode_id", "content_descriptor_id"], name: "idx_ecd_on_episode_and_descriptor", unique: true
    t.index ["episode_id"], name: "index_episode_content_descriptors_on_episode_id"
  end

  create_table "episodes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.string "thumbnail"
    t.boolean "premium", default: false
    t.string "thumbnail_resized"
    t.uuid "season_id", null: false
    t.integer "tmdb_id"
    t.uuid "content_rating_id"
    t.string "content_rating_code"
    t.index ["content_rating_id"], name: "index_episodes_on_content_rating_id"
    t.index ["season_id", "position"], name: "index_episodes_on_season_id_and_position"
    t.index ["season_id"], name: "index_episodes_on_season_id"
    t.index ["tmdb_id"], name: "index_episodes_on_tmdb_id", unique: true, where: "(tmdb_id IS NOT NULL)"
  end

  create_table "image_variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "imageable_type", null: false
    t.string "image_type", null: false
    t.string "variant", null: false
    t.string "format", null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "imageable_id", null: false
    t.index ["image_type", "variant", "format"], name: "index_image_variants_on_image_type_and_variant_and_format"
    t.index ["imageable_type", "imageable_id", "image_type", "variant", "format"], name: "idx_image_variants_on_lookup", unique: true
    t.index ["imageable_type", "imageable_id"], name: "index_image_variants_on_imageable"
  end

  create_table "likes", force: :cascade do |t|
    t.uuid "profile_id"
    t.uuid "content_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_likes_on_content_id"
    t.index ["created_at"], name: "index_likes_on_created_at"
    t.index ["profile_id"], name: "index_likes_on_profile_id"
    t.index ["updated_at"], name: "index_likes_on_updated_at"
  end

  create_table "live_chat_messages", force: :cascade do |t|
    t.bigint "live_event_id", null: false
    t.uuid "profile_id", null: false
    t.string "message_type", default: "user", null: false
    t.text "body"
    t.boolean "deleted", default: false, null: false
    t.datetime "deleted_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_event_id", "created_at"], name: "index_live_chat_messages_on_live_event_id_and_created_at"
    t.index ["live_event_id"], name: "index_live_chat_messages_on_live_event_id"
    t.index ["message_type"], name: "index_live_chat_messages_on_message_type"
    t.index ["profile_id"], name: "index_live_chat_messages_on_profile_id"
  end

  create_table "live_event_attendees", force: :cascade do |t|
    t.bigint "live_event_id", null: false
    t.uuid "profile_id", null: false
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_event_id", "profile_id"], name: "index_live_event_attendees_on_live_event_id_and_profile_id", unique: true
    t.index ["live_event_id"], name: "index_live_event_attendees_on_live_event_id"
    t.index ["profile_id"], name: "index_live_event_attendees_on_profile_id"
  end

  create_table "live_events", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.uuid "organizer_id", null: false
    t.string "title"
    t.text "description"
    t.datetime "starts_at", null: false
    t.datetime "estimated_end_at"
    t.integer "status", default: 0, null: false
    t.integer "max_participants"
    t.boolean "is_public", default: true, null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_live_events_on_content_id"
    t.index ["organizer_id"], name: "index_live_events_on_organizer_id"
    t.index ["status", "starts_at"], name: "index_live_events_on_status_and_starts_at"
    t.index ["status"], name: "index_live_events_on_status"
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
    t.uuid "current_profile_id"
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

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.uuid "user_id", null: false
    t.string "provider_key", null: false
    t.string "provider_invoice_id"
    t.string "provider_payment_id"
    t.string "kind", default: "renewal", null: false
    t.string "status", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", limit: 3, null: false
    t.datetime "attempted_at"
    t.datetime "paid_at"
    t.string "failure_code"
    t.text "failure_message"
    t.jsonb "provider_metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_key", "provider_invoice_id"], name: "index_payments_remote_invoice_id", unique: true, where: "(provider_invoice_id IS NOT NULL)"
    t.index ["provider_key", "provider_payment_id"], name: "index_payments_remote_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["subscription_id"], name: "index_payments_on_subscription_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "tmdb_id", null: false
    t.string "name", null: false
    t.string "profile_path"
    t.string "known_for_department", default: "Acting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tmdb_id"], name: "index_people_on_tmdb_id", unique: true
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

  create_table "provider_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider_key", null: false
    t.string "provider_event_id"
    t.string "event_type", null: false
    t.string "resource_type"
    t.string "resource_id"
    t.boolean "signature_valid", null: false
    t.datetime "occurred_at"
    t.datetime "received_at", null: false
    t.datetime "processed_at"
    t.text "processing_error"
    t.integer "attempt_count", default: 0, null: false
    t.string "payload_sha256", null: false
    t.jsonb "payload", default: {}, null: false
    t.jsonb "headers", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_key", "event_type", "resource_id", "payload_sha256"], name: "index_provider_events_dedup_fallback", unique: true
    t.index ["provider_key", "provider_event_id"], name: "index_provider_events_external_id", unique: true, where: "(provider_event_id IS NOT NULL)"
  end

  create_table "reproductions", force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "content_id", null: false
    t.datetime "played_at", null: false
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_reproductions_on_content_id"
    t.index ["country_code"], name: "index_reproductions_on_country_code"
    t.index ["played_at"], name: "index_reproductions_on_played_at"
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

  create_table "seasons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.uuid "content_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.integer "tmdb_id"
    t.index ["content_id", "position"], name: "index_seasons_on_content_id_and_position"
    t.index ["content_id"], name: "index_seasons_on_content_id"
    t.index ["tmdb_id"], name: "index_seasons_on_tmdb_id", unique: true, where: "(tmdb_id IS NOT NULL)"
  end

  create_table "segments", force: :cascade do |t|
    t.float "start_time"
    t.float "end_time"
    t.string "segment_type", null: false
    t.string "segmentable_type", null: false
    t.string "segmentable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["segment_type"], name: "index_segments_on_segment_type"
    t.index ["segmentable_type", "segmentable_id", "start_time"], name: "index_segments_on_type_and_id_and_start_time"
    t.index ["segmentable_type", "segmentable_id"], name: "index_segments_on_segmentable_type_and_segmentable_id"
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

  create_table "subscription_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "granted_by_user_id"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "reason", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["granted_by_user_id"], name: "index_subscription_access_grants_on_granted_by_user_id"
    t.index ["user_id", "starts_at", "ends_at"], name: "index_access_grants_active_lookup"
    t.index ["user_id"], name: "index_subscription_access_grants_on_user_id"
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

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "offering_key", default: "cinelartv_membership_monthly", null: false
    t.string "status", default: "pending", null: false
    t.string "provider_key", null: false
    t.string "provider_subscription_id"
    t.string "provider_customer_id"
    t.string "provider_plan_id"
    t.bigint "amount_cents", null: false
    t.string "currency", limit: 3, null: false
    t.string "interval_unit", default: "month", null: false
    t.integer "interval_count", default: 1, null: false
    t.datetime "current_period_started_at"
    t.datetime "current_period_ends_at"
    t.datetime "access_until"
    t.datetime "grace_ends_at"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.datetime "remote_updated_at"
    t.datetime "last_reconciled_at"
    t.jsonb "provider_metadata", default: {}, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_until"], name: "index_subscriptions_on_access_until"
    t.index ["provider_key", "provider_subscription_id"], name: "index_subscriptions_remote_id", unique: true, where: "(provider_subscription_id IS NOT NULL)"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_one_open_subscription_per_user", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'past_due'::character varying, 'cancelled'::character varying])::text[]))"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
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
    t.index ["xmltv_id"], name: "index_tv_programs_on_xmltv_id"
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
    t.string "purchase_token"
    t.string "iap_product_id"
    t.string "external_id"
    t.index ["created_at"], name: "index_user_subscriptions_on_created_at"
    t.index ["external_id"], name: "index_user_subscriptions_on_external_id"
    t.index ["provider", "provider_subscription_id"], name: "idx_user_subscriptions_provider_external_id", unique: true, where: "(provider_subscription_id IS NOT NULL)"
    t.index ["provider"], name: "index_user_subscriptions_on_provider"
    t.index ["purchase_token"], name: "index_user_subscriptions_on_purchase_token"
    t.index ["status"], name: "index_user_subscriptions_on_status"
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
    t.boolean "suspended", default: false, null: false
    t.datetime "suspended_until"
    t.text "suspended_reason"
    t.uuid "suspended_by_id"
    t.datetime "deactivated_at"
    t.text "deactivated_reason"
    t.uuid "deactivated_by_id"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["deactivated_at"], name: "index_users_on_deactivated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended_until"], name: "index_users_on_suspended_until"
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
    t.boolean "trailer", default: false, null: false
    t.index ["last_checked_at"], name: "index_video_sources_on_last_checked_at"
    t.index ["media_status", "last_checked_at"], name: "index_video_sources_on_media_status_and_last_checked"
    t.index ["media_status"], name: "index_video_sources_on_media_status"
    t.index ["status"], name: "index_video_sources_on_status"
    t.index ["videoable_id", "videoable_type", "trailer"], name: "index_video_sources_on_videoable_and_trailer"
    t.index ["videoable_type", "videoable_id"], name: "index_video_sources_on_videoable"
  end

  create_table "watch_party_session_users", force: :cascade do |t|
    t.bigint "watch_party_session_id", null: false
    t.uuid "user_id", null: false
    t.boolean "is_host", default: false
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_watch_party_session_users_on_user_id"
    t.index ["watch_party_session_id", "user_id"], name: "idx_on_watch_party_session_id_user_id_46fa650fed", unique: true
    t.index ["watch_party_session_id"], name: "index_watch_party_session_users_on_watch_party_session_id"
  end

  create_table "watch_party_sessions", force: :cascade do |t|
    t.string "content_id", null: false
    t.uuid "host_id", null: false
    t.uuid "user_id", null: false
    t.float "playback_current_time", default: 0.0
    t.boolean "is_playing", default: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "last_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "live_event_id"
    t.boolean "is_public", default: false, null: false
    t.float "playback_position", default: 0.0
    t.datetime "last_playback_update_at"
    t.datetime "last_activity_at"
    t.index ["content_id"], name: "index_watch_party_sessions_on_content_id"
    t.index ["host_id"], name: "index_watch_party_sessions_on_host_id"
    t.index ["is_public", "ended_at"], name: "index_watch_party_sessions_on_is_public_and_ended_at"
    t.index ["live_event_id"], name: "index_watch_party_sessions_on_live_event_id"
    t.index ["user_id"], name: "index_watch_party_sessions_on_user_id"
  end

  create_table "watch_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "content_id", null: false
    t.uuid "episode_id"
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.float "duration_watched", default: 0.0, null: false
    t.float "total_duration", default: 0.0, null: false
    t.boolean "completed", default: false, null: false
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "last_progress", default: 0.0, null: false
    t.index ["completed"], name: "index_watch_sessions_on_completed"
    t.index ["content_id", "started_at"], name: "index_watch_sessions_on_content_id_and_started_at"
    t.index ["content_id"], name: "index_watch_sessions_on_content_id"
    t.index ["episode_id"], name: "index_watch_sessions_on_episode_id"
    t.index ["profile_id", "content_id", "episode_id", "started_at"], name: "index_watch_sessions_on_profile_content_episode_started", order: { started_at: :desc }
    t.index ["profile_id", "content_id"], name: "index_watch_sessions_active", where: "(ended_at IS NULL)"
    t.index ["profile_id", "started_at"], name: "index_watch_sessions_on_profile_id_and_started_at"
    t.index ["profile_id"], name: "index_watch_sessions_on_profile_id"
    t.index ["started_at"], name: "index_watch_sessions_on_started_at"
  end

  create_table "webhook_logs", force: :cascade do |t|
    t.string "event_name"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_logs_on_created_at"
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

  add_foreign_key "cast_members", "contents"
  add_foreign_key "cast_members", "people"
  add_foreign_key "content_analytics", "contents"
  add_foreign_key "content_categories", "categories", on_delete: :cascade
  add_foreign_key "content_categories", "contents", on_delete: :cascade
  add_foreign_key "content_content_descriptors", "content_descriptors"
  add_foreign_key "content_content_descriptors", "contents"
  add_foreign_key "contents", "content_ratings"
  add_foreign_key "continue_watchings", "contents"
  add_foreign_key "continue_watchings", "episodes"
  add_foreign_key "continue_watchings", "profiles"
  add_foreign_key "dislikes", "contents"
  add_foreign_key "dislikes", "profiles"
  add_foreign_key "episode_content_descriptors", "content_descriptors"
  add_foreign_key "episode_content_descriptors", "episodes"
  add_foreign_key "episodes", "content_ratings"
  add_foreign_key "episodes", "seasons"
  add_foreign_key "likes", "contents"
  add_foreign_key "likes", "profiles"
  add_foreign_key "live_chat_messages", "live_events"
  add_foreign_key "live_chat_messages", "profiles"
  add_foreign_key "live_event_attendees", "live_events"
  add_foreign_key "live_event_attendees", "profiles"
  add_foreign_key "live_events", "contents"
  add_foreign_key "live_events", "users", column: "organizer_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_device_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_device_grants", "users", column: "resource_owner_id"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "payments", "users"
  add_foreign_key "preferences", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "reproductions", "contents"
  add_foreign_key "reproductions", "profiles"
  add_foreign_key "seasons", "contents"
  add_foreign_key "subscription_access_grants", "users"
  add_foreign_key "subscription_access_grants", "users", column: "granted_by_user_id"
  add_foreign_key "subscription_payments", "user_subscriptions"
  add_foreign_key "subscription_payments", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tv_programs", "live_tv_channels"
  add_foreign_key "watch_party_session_users", "users"
  add_foreign_key "watch_party_session_users", "watch_party_sessions"
  add_foreign_key "watch_party_sessions", "live_events"
  add_foreign_key "watch_party_sessions", "users"
  add_foreign_key "watch_party_sessions", "users", column: "host_id"
  add_foreign_key "watch_sessions", "contents"
  add_foreign_key "watch_sessions", "episodes", on_delete: :cascade
  add_foreign_key "watch_sessions", "profiles"
end
