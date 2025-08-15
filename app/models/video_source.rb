# frozen_string_literal: true

class VideoSource < ApplicationRecord
  belongs_to :videoable, polymorphic: true

  validates :url, presence: true
  validates :quality, presence: true
  validates :format, presence: true
  validates :storage_location, presence: true

  enum storage_location: {
    local: "local",
    s3: "cloud",
    external_url: "external_url",
  }

  enum format: {
    mp4: "mp4",
    m3u8: "m3u8",
  }

  # If the format is m3u8, the quality is adaptative

  enum quality: {
    "144": "144p",
    "240": "240p",
    "360": "360p",
    "480": "480p",
    "720": "720p",
    "1080": "1080p",
    "1440": "1440p",
    "2160": "2160p",
    adaptative: "adaptative",
    legacy: "legacy",
  }
end
