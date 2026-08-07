# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  include Videoable
  include Segmenteable
  include Imageable

  belongs_to :season
  has_one :content, through: :season

  validates :title, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true

  after_commit :touch_season, on: %i[create update destroy]

  before_destroy :delete_associated_continue_watching
  before_destroy :cleanup_thumbnail

  # Legacy accessor (backward compat)
  def thumbnail
    image_url_for("episode_thumbnail")
  end

  def thumbnail_resized
    image_url_for("episode_thumbnail", variant: "medium")
  end

  def delete_associated_continue_watching
    ContinueWatching.where(episode_id: id).destroy_all
  end

  private

  def cleanup_thumbnail
    destroy_all_images
  end

  def touch_season
    season&.touch
  end
end
