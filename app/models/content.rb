# frozen_string_literal: true

class Content < ApplicationRecord
  include Videoable
  include Segmenteable
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
                                 tmdb_id]))
  end

  has_many :seasons, dependent: :destroy
  has_many :cast_members, dependent: :destroy
  has_many :people, through: :cast_members
  has_many :continue_watchings, dependent: :destroy
  has_and_belongs_to_many :liking_profiles, class_name: "Profile", join_table: "likes"

  similar_by :liking_profiles

  # Cast-based similarity for combined recommendations
  SIMILARITY_SOURCES = [
    { assoc: :liking_profiles, weight: 0.7 },
    { assoc: :people, weight: 0.3 }
  ].freeze

  def similar_items(n_results: 10)
    combined_similar_items(SIMILARITY_SOURCES, n_results: n_results)
  end

  enum :content_type, { TVSHOW: "TVSHOW", MOVIE: "MOVIE" }

  validates :title, presence: true
  validates :content_type, presence: true
  validates :year, numericality: { only_integer: true }, allow_nil: true
  validate :trailer_url_must_be_video, if: :trailer_url?

  has_many :trailer_video_sources, -> { trailers }, class_name: "VideoSource", as: :videoable

  scope :available, -> { where(available: true) }
  scope :premium, -> { where(premium: true) }
  scope :free, -> { where(premium: false) }

  scope :added_recently, lambda {
    where(available: true)
      .where("created_at > ?", 3.weeks.ago)
      .order(created_at: :desc)
      .limit(15)
  }

  scope :new_this_week, lambda {
    where(available: true)
      .where("created_at > ?", 1.week.ago)
      .order(created_at: :desc)
      .limit(15)
  }

  scope :trending, lambda { |limit = 15|
    joins(:reproductions)
      .where(available: true)
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
      .where(available: true)
      .order(Arel.sql("COALESCE(content_analytics.total_views, 0) DESC"))
      .limit(limit)
  }

  scope :most_liked, lambda { |limit = 15|
    left_joins(:liking_profiles)
      .where(available: true)
      .group("contents.id")
      .order(Arel.sql("COUNT(likes.profile_id) DESC"))
      .limit(limit)
  }

  scope :by_category_id, lambda { |category_id, limit = 10|
    joins(:content_categories)
      .where(available: true, content_categories: { category_id: category_id })
      .limit(limit)
  }

  scope :search_by_title_and_description, lambda { |query|
    normalized = ActiveRecord::Base.sanitize_sql_like(query.to_s.downcase.gsub(/[-\s]/, ""))
    where(
      "available = true AND (" \
      "unaccent(lower(title)) LIKE unaccent(?) OR " \
      "unaccent(lower(description)) LIKE unaccent(?))",
      "%#{normalized}%", "%#{normalized}%"
    )
  }

  before_destroy :cleanup_images

  def update_categories(category_ids)
    self.category_ids = category_ids
  end

  private

  def trailer_url_must_be_video
    return unless trailer_url.present?
    return if trailer_url.match?(/\.(mp4|m3u8|webm)(\?.*)?\z/i)

    errors.add(:trailer_url, "must be a direct video URL (.mp4, .m3u8, or .webm)")
  end

  def cleanup_images
    cleanup_image_file(banner, "banners")
    cleanup_image_file(cover, "covers")
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
      resized_path = Rails.root.join("public", "uploads", "content_images", subfolder, "resized_image", filename)
      File.delete(resized_path) if File.exist?(resized_path)
    else
      # S3 storage cleanup - rely on overwrite for now
      Rails.logger.info("S3 storage detected - old image cleanup skipped (relying on overwrite)")
    end
  end
end
