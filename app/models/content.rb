# frozen_string_literal: true

# app/models/content.rb
class Content < ApplicationRecord
  has_many :content_categories
  has_many :categories, through: :content_categories
  has_many :seasons

  validates :title, presence: true
  validates :content_type, presence: true
  validates_inclusion_of :content_type, in: ["TVSHOW", "MOVIE"]
  validates :year, numericality: { only_integer: true }, allow_nil: true

  def self.search(title)
    where("LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{title}%", "%#{title}%")
  end

  def self.find_by_type(type)
    where(type: type)
  end

  def update_categories(category_ids)
    self.category_ids = category_ids
  end

  def self.banner_content
    # Only can appear in the banner if it has a banner image
    where.not(banner: nil).order("RANDOM()").limit(5)
  end

  def self.homepage_data
    @homepage_data = {}
    @homepage_data[:banner_content] = banner_content

    @homepage_data
  end

  def add_season(season)
    seasons << season
  end
end
