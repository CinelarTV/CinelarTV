# frozen_string_literal: true

class MigrateContentToVideoSources < ActiveRecord::Migration[7.0]
  def change
    Content.find_each do |content|
      next if content.url.blank?
      content.video_sources.create!(
        video_link_or_file: content.url,
        quality: "legacy",
        format: content.url.split(".").last == "mp4" ? "mp4" : "m3u8",
        storage_location: "cloud",
      )
    end
  end
end
