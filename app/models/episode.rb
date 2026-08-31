# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  include Videoable
  include Segmenteable
  include Imageable

  belongs_to :season
  has_one :content, through: :season
  has_many :watch_sessions, dependent: :destroy

  belongs_to :content_rating, optional: true
  has_many :episode_content_descriptors, dependent: :destroy
  has_many :content_descriptors, through: :episode_content_descriptors

  validates :title, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true

  after_commit :touch_season, on: %i[create update destroy]

  before_destroy :delete_associated_continue_watching
  before_destroy :cleanup_thumbnail

  def effective_content_rating
    content_rating || season&.content&.content_rating
  end

  def effective_descriptors(locale: I18n.locale)
    own = content_descriptors.to_a
    if own.empty?
      parent_descriptors = season&.content&.content_descriptors&.to_a || []
      return parent_descriptors
    end
    own
  end

  def advisory_text(locale: I18n.locale)
    rc = effective_content_rating
    return nil unless rc

    descriptor_names = effective_descriptors(locale: locale).map { |d| d.name_for(locale) }.first(3)
    text = rc.name_for(locale)
    text += " \u00b7 #{descriptor_names.join(', ')}" if descriptor_names.any?
    text
  end

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
