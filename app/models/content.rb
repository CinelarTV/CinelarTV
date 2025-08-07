# frozen_string_literal: true

# app/models/content.rb
class Content < ApplicationRecord
  include Videoable

  has_many :content_categories
  has_many :categories, through: :content_categories
  has_many :seasons

  enum :content_type, { TVSHOW: "TVSHOW", MOVIE: "MOVIE" }

  has_and_belongs_to_many :liking_profiles, class_name: "Profile", join_table: "likes"

  include SimpleRecommender::Recommendable
  similar_by :liking_profiles

  validates :title, presence: true
  validates :content_type, presence: true
  validates_inclusion_of :content_type, in: %w[TVSHOW MOVIE]
  validates :year, numericality: { only_integer: true }, allow_nil: true

  # On destroy, delete the associated and continue watching
  before_destroy :delete_seasons
  before_destroy :delete_associated_continue_watching

  def self.search(title)
    where("available = ? AND (LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?))", true, "%#{title}%",
          "%#{title}%")
  end

  def self.find_by_type(type)
    where(type:)
  end

  def update_categories(category_ids)
    self.category_ids = category_ids
  end

  def self.banner_content
    # Only can appear in the banner if it has a banner image
    where.not(banner: nil).order("RANDOM()").limit(5)
  end

  def add_season(season)
    seasons << season
  end

  def delete_seasons
    seasons.destroy_all
  end

  def delete_associated_continue_watching
    ContinueWatching.where(content_id: id).destroy_all
  end

  def self.added_recently
    where(available: true)
      .where("created_at > ?", 3.week.ago)
      .order(created_at: :desc)
      .limit(15)
  end

  # Búsqueda robusta: insensible a acentos, mayúsculas, guiones y espacios
  scope :search_by_title_and_description, ->(query) {
    normalized_query = query.to_s.downcase.gsub(/[-\s]/, "")
    where(
      "available = true AND (" \
      "regexp_replace(unaccent(lower(title)), '[-\\s]', '', 'g') LIKE ? OR " \
      "regexp_replace(unaccent(lower(description)), '[-\\s]', '', 'g') LIKE ?)",
      "%#{normalized_query}%", "%#{normalized_query}%"
    )
  }
end
