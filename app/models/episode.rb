# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  include Videoable
  include Segmenteable

  belongs_to :season
  has_one :content, through: :season

  validates :title, presence: true
  validates :description, presence: true

  before_destroy :delete_associated_continue_watching
  before_destroy :cleanup_thumbnail

  def delete_associated_continue_watching
    ContinueWatching.where(episode_id: id).destroy_all
  end

  private

  def cleanup_thumbnail
    cleanup_image_file(thumbnail, "episode_thumbnails")
  end

  def cleanup_image_file(url, subfolder)
    return unless url.present?

    url_without_query = url.split("?").first
    filename = url_without_query.split("/").last

    # Handle both local and S3 storage
    if SiteSetting.storage_provider == "local"
      store_dir = Rails.root.join("public", "uploads", "content_images", subfolder, filename)
      File.delete(store_dir) if File.exist?(store_dir)

      # Clean up resized version
      resized_filename = "resized_#{filename}"
      resized_path = Rails.root.join("public", "uploads", "content_images", subfolder, resized_filename)
      File.delete(resized_path) if File.exist?(resized_path)
    else
      # S3 storage cleanup - rely on overwrite for now
      Rails.logger.info("S3 storage detected - old image cleanup skipped (relying on overwrite)")
    end
  end
end
