# frozen_string_literal: true

namespace :reproductions do
  desc "Backfill episode_id on reproductions using WatchSession data"
  task backfill_episode_id: :environment do
    puts "=== Reproductions Episode ID Backfill ==="
    puts ""

    total = Reproduction.where(episode_id: nil).count
    puts "Reproductions without episode_id: #{total}"
    puts ""

    if total.zero?
      puts "Nothing to do!"
      next
    end

    updated = 0
    skipped = 0
    batch_size = 1000

    Reproduction.where(episode_id: nil)
                .includes(:profile, :content)
                .find_each(batch_size: batch_size) do |reproduction|
      # Skip live TV (content_id is nil)
      unless reproduction.content_id
        skipped += 1
        next
      end

      # Find closest WatchSession by (profile_id, content_id)
      played_at = reproduction.played_at || reproduction.created_at
      quoted_time = Reproduction.connection.quote(played_at)

      session = WatchSession.where(
        profile_id: reproduction.profile_id,
        content_id: reproduction.content_id
      )
                            .where.not(episode_id: nil)
                            .order(Arel.sql("ABS(EXTRACT(EPOCH FROM (started_at - #{quoted_time})))"))
                            .limit(1)
                            .first

      if session&.episode_id
        reproduction.update_column(:episode_id, session.episode_id)
        updated += 1
      else
        skipped += 1
      end

      print "." if (updated + skipped) % 500 == 0
    end

    puts ""
    puts ""
    puts "Done! Updated: #{updated}, Skipped (no matching session): #{skipped}"
    puts "Remaining without episode_id: #{Reproduction.where(episode_id: nil).count}"
  end
end
