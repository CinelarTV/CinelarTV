# frozen_string_literal: true

class AddAdvancedPerformanceIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Create immutable wrapper for unaccent (required for GIN index expressions)
    enable_extension "unaccent" unless extension_enabled?("unaccent")
    execute <<~SQL
      CREATE OR REPLACE FUNCTION immutable_unaccent(text)
      RETURNS text AS $$
        SELECT unaccent('unaccent', $1)
      $$ LANGUAGE sql IMMUTABLE;
    SQL

    # Búsqueda por título: GIN trigram para LIKE %..% con unaccent
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_contents_on_title_trgm
      ON contents USING gin (lower(immutable_unaccent(title)) gin_trgm_ops)
    SQL

    # added_recently / new_this_week: WHERE available=TRUE AND created_at > ? ORDER BY created_at DESC
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_contents_on_available_and_created_at
      ON contents (created_at DESC) WHERE (available = true)
    SQL

    # Dashboard statistics: GROUP BY DATE(likes.created_at)
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_likes_on_created_at
      ON likes (created_at)
    SQL

    # XMLTV cleanup: WHERE xmltv_id = ? AND start_time BETWEEN
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_tv_programs_on_xmltv_id
      ON tv_programs (xmltv_id)
    SQL

    # update_watch_session: WHERE profile_id=? AND content_id=? AND episode_id=? ORDER BY started_at DESC
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_watch_sessions_on_profile_content_episode_started
      ON watch_sessions (profile_id, content_id, episode_id, started_at DESC)
    SQL

    # Active watch sessions: WHERE ended_at IS NULL (partial)
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_watch_sessions_active
      ON watch_sessions (profile_id, content_id) WHERE (ended_at IS NULL)
    SQL

    # MediaScannerJob: WHERE media_status != 'checking' ORDER BY media_status DESC, last_checked_at ASC
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_video_sources_on_media_status_and_last_checked
      ON video_sources (media_status, last_checked_at)
    SQL

    # Webhook logs: ORDER BY created_at DESC LIMIT N
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_webhook_logs_on_created_at
      ON webhook_logs (created_at)
    SQL

    # User subscriptions scope active: status filter
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_user_subscriptions_on_status
      ON user_subscriptions (status)
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_contents_on_title_trgm"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_contents_on_available_and_created_at"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_likes_on_created_at"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_tv_programs_on_xmltv_id"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_watch_sessions_on_profile_content_episode_started"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_watch_sessions_active"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_video_sources_on_media_status_and_last_checked"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_webhook_logs_on_created_at"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_user_subscriptions_on_status"
    execute "DROP FUNCTION IF EXISTS immutable_unaccent(text)"
  end
end
