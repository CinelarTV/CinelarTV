# frozen_string_literal: true

class MigrateEpisodeToVideoSources < ActiveRecord::Migration[7.0]
  def change
    Episode.find_each do |episode|
      next if episode.url.blank?
      episode.video_sources.create!(
        video_link_or_file: episode.url,
        quality: "legacy",
        format: episode.url.split(".").last == "mp4" ? "mp4" : "m3u8",
        storage_location: "cloud",
      )
    end
  end
end
