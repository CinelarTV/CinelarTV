# frozen_string_literal: true

class VideoSource < ApplicationRecord
  belongs_to :videoable, polymorphic: true

  validates :url, presence: true, unless: :temp_path_present?
  validates :quality, presence: true, unless: :temp_path_present?
  validates :format, presence: true, unless: :temp_path_present?
  validates :storage_location, presence: true

  scope :trailers, -> { where(trailer: true) }
  scope :content_sources, -> { where(trailer: [false, nil]) }

  enum :storage_location, {
    local: "local",
    s3: "cloud",
    external_url: "external_url",
  }

  enum :format, {
    mp4: "mp4",
    m3u8: "m3u8",
  }

  # If the format is m3u8, the quality is adaptative

  enum :quality, {
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

  enum :media_status, {
    checking: "checking",
    verified: "verified",
    broken: "broken",
    uncertain: "uncertain",
  }

  before_save :reset_integrity_on_url_change, if: :url_changed?
  before_destroy :stop_transcoding_and_cleanup

  private

  def reset_integrity_on_url_change
    self.media_status = "verified"
    self.failure_count = 0
  end

  def stop_transcoding_and_cleanup
    Rails.logger.info "Cleaning up VideoSource #{id}: status=#{status}, temp_path=#{temp_path}, url=#{url}"

    # Always try to clean up transcoded files (both local and S3)
    Rails.logger.info "Cleaning up transcoded files"
    TranscodedFileStorageService.cleanup_transcoded_files(self)

    # Delete temporary file if exists
    if temp_path.present?
      if File.exist?(temp_path)
        FileUtils.rm_f(temp_path)
        Rails.logger.info "Deleted temporary file: #{temp_path}"
      else
        Rails.logger.warn "Temporary file does not exist: #{temp_path}"
      end
    else
      Rails.logger.info "No temp_path to delete"
    end

    # Also clean up transcoding output directory if exists
    transcoding_dir = Rails.root.join('tmp', 'transcoding', id.to_s)
    if Dir.exist?(transcoding_dir)
      FileUtils.rm_rf(transcoding_dir)
      Rails.logger.info "Deleted transcoding directory: #{transcoding_dir}"
    else
      Rails.logger.info "Transcoding directory does not exist: #{transcoding_dir}"
    end
  rescue StandardError => e
    Rails.logger.error "Error cleaning up VideoSource #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def temp_path_present?
    temp_path.present?
  end
end
