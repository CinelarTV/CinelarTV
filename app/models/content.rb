# frozen_string_literal: true

class Content < ApplicationRecord
  include Videoable
  include SimpleRecommender::Recommendable

  attribute :available, :boolean, default: false

  has_many :content_categories
  has_many :categories, through: :content_categories
  has_many :seasons, dependent: :destroy
  has_many :continue_watchings, dependent: :destroy
  has_and_belongs_to_many :liking_profiles, class_name: "Profile", join_table: "likes"

  similar_by :liking_profiles

  enum :content_type, { TVSHOW: "TVSHOW", MOVIE: "MOVIE" }

  validates :title, presence: true
  validates :content_type, presence: true
  validates :year, numericality: { only_integer: true }, allow_nil: true

  scope :available, -> { where(available: true) }
  scope :premium, -> { where(premium: true) }
  scope :free, -> { where(premium: false) }

  scope :added_recently, -> {
    where(available: true)
      .where("created_at > ?", 3.weeks.ago)
      .order(created_at: :desc)
      .limit(15)
  }

  scope :banner_content, -> {
    where.not(banner: nil).order("RANDOM()").limit(5)
  }

  scope :by_type, ->(type) { where(content_type: type) }

  scope :search_by_title_and_description, ->(query) {
    normalized = ActiveRecord::Base.sanitize_sql_like(query.to_s.downcase.gsub(/[-\s]/, ""))
    where(
      "available = true AND (" \
      "regexp_replace(unaccent(lower(title)), '[-\\s]', '', 'g') LIKE ? OR " \
      "regexp_replace(unaccent(lower(description)), '[-\\s]', '', 'g') LIKE ?)",
      "%#{normalized}%", "%#{normalized}%"
    )
  }

  def update_categories(category_ids)
    self.category_ids = category_ids
  end
end