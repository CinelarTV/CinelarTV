# frozen_string_literal: true

# app/models/category.rb
class Category < ApplicationRecord
  has_many :content_categories
  has_many :contents, through: :content_categories

  validates :name, presence: true
  validates :description, presence: true
  validates :image, presence: true, allow_blank: true # Assuming image is stored as a URL

  def description_with_format
    "Description: #{description}"
  end

  def has_image?
    image.present?
  end

  def image_url
    "https://example.com/images/#{image}" if image.present?
  end

  def as_json(options = {})
    super(options.merge(only: %i[id name description image]))
  end

  def update_data(data)
    self.name = data[:name] if data[:name]
    self.description = data[:description] if data[:description]
    self.image = data[:image] if data[:image]
  end
end
