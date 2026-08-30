# frozen_string_literal: true

class Content < ApplicationRecord
  include Videoable
  include Segmenteable
  include Imageable
  include SimpleRecommender::Recommendable

  attribute :available, :boolean, default: false
  attribute :tmdb_id, :string

  has_many :content_categories
  has_many :categories, through: :content_categories
  has_many :reproductions, dependent: :destroy
  has_many :watch_sessions, dependent: :destroy
  has_one :content_analytic, dependent: :destroy

  def as_json(options = {})
    super(options.merge(only: %i[id title description banner cover content_type year available premium trailer_url
                                 tmdb_id scheduled_launch_at]))
  end

  has_many :seasons, dependent: :destroy
  has_many :cast_members, dependent: :destroy
  has_many :people, through: :cast_members
  has_many :continue_watchings, dependent: :destroy
  has_and_belongs_to_many :liking_profiles, class_name: "Profile", join_table: "likes"
  has_and_belongs_to_many :disliking_profiles, class_name: "Profile", join_table: "dislikes"

  similar_by :liking_profiles

  # Cast-based similarity for combined recommendations
  SIMILARITY_SOURCES = [
    { assoc: :liking_profiles, weight: 0.7 },
    { assoc: :people, weight: 0.3 }
  ].freeze

  def similar_items(n_results: 10)
    Rails.cache.fetch("similar/#{id}/#{updated_at.to_i}", expires_in: 6.hours) do
      combined_similar_items(SIMILARITY_SOURCES, n_results: n_results)
    end
  end

  enum :content_type, { TVSHOW: "TVSHOW", MOVIE: "MOVIE" }

  validates :title, presence: true
  validates :content_type, presence: true
  validates :year, numericality: { only_integer: true }, allow_nil: true
  validates :scheduled_launch_at, presence: true, if: -> { scheduled_launch_at.present? }
  validate :trailer_url_must_be_video, if: :trailer_url?
  validate :scheduled_launch_at_must_be_future, on: :update

  has_many :trailer_video_sources, -> { trailers }, class_name: "VideoSource", as: :videoable

  scope :available, -> { where(available: true).launched_or_unscheduled }
  scope :premium, -> { where(premium: true) }
  scope :free, -> { where(premium: false) }

  scope :launched_or_unscheduled, -> {
    where("scheduled_launch_at IS NULL OR scheduled_launch_at <= ?", Time.current)
  }

  scope :scheduled_pending, -> {
    where("scheduled_launch_at IS NOT NULL AND scheduled_launch_at > ? AND available = false", Time.current)
  }

  scope :added_recently, lambda {
    available
      .where("created_at > ?", 3.weeks.ago)
      .order(created_at: :desc)
      .limit(15)
  }

  scope :new_this_week, lambda {
    available
      .where("created_at > ?", 1.week.ago)
      .order(created_at: :desc)
      .limit(15)
  }

  scope :trending, lambda { |limit = 15|
    joins(:reproductions)
      .available
      .where("reproductions.played_at > ?", 7.days.ago)
      .group("contents.id")
      .order(Arel.sql("COUNT(reproductions.id) DESC"))
      .limit(limit)
  }

  scope :banner_content, lambda {
    where.not(banner: nil).order("RANDOM()").limit(5)
  }

  scope :by_type, ->(type) { where(content_type: type) }

  scope :most_viewed, lambda { |limit = 15|
    left_joins(:content_analytic)
      .available
      .order(Arel.sql("COALESCE(content_analytics.total_views, 0) DESC"))
      .limit(limit)
  }

  scope :most_liked, lambda { |limit = 15|
    left_joins(:liking_profiles)
      .available
      .group("contents.id")
      .order(Arel.sql("COUNT(likes.profile_id) DESC"))
      .limit(limit)
  }

  scope :by_category_id, lambda { |category_id, limit = 10|
    joins(:content_categories)
      .available
      .where(content_categories: { category_id: category_id })
      .limit(limit)
  }

  before_destroy :cleanup_images
  after_commit :clear_global_sections_cache, if: -> { saved_change_to_available? || saved_change_to_created_at? }
  after_save :update_search_data, if: -> { saved_change_to_title? || saved_change_to_description? }

  # Legacy accessors (backward compat, read from image_variants)
  def banner
    backdrop_url
  end

  def cover
    poster_url
  end

  def banner_resized
    image_url_for("backdrop", variant: "medium")
  end

  def cover_resized
    image_url_for("poster", variant: "medium")
  end

  def update_categories(category_ids)
    self.category_ids = category_ids
  end

  def self.publish_scheduled!
    where("scheduled_launch_at IS NOT NULL AND scheduled_launch_at <= ? AND available = false", Time.current)
      .update_all(available: true, scheduled_launch_at: nil)
  end

  def scheduled?
    scheduled_launch_at.present? && scheduled_launch_at > Time.current && !available?
  end

  private

  def scheduled_launch_at_must_be_future
    return if scheduled_launch_at.blank?

    errors.add(:scheduled_launch_at, "must be in the future") if scheduled_launch_at <= Time.current
  end

  def trailer_url_must_be_video
    return unless trailer_url.present?
    return if trailer_url.match?(/\.(mp4|m3u8|webm)(\?.*)?\z/i)

    errors.add(:trailer_url, "must be a direct video URL (.mp4, .m3u8, or .webm)")
  end

  def cleanup_images
    destroy_all_images
  end

  def clear_global_sections_cache
    CinelarTV.cache.delete("homepage/global_sections")
  end

  def update_search_data
    update_column(:search_data,
      Arel.sql(<<~SQL.squish)
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(title, ''))), 'A') ||
        setweight(to_tsvector('simple', immutable_unaccent(coalesce(description, ''))), 'B')
      SQL
    )
  end
end
