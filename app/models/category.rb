# frozen_string_literal: true

# app/models/category.rb
class Category < ApplicationRecord
  has_many :content_categories
  has_many :contents, through: :content_categories

  validates :name, presence: true
  validates :description, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true

  def as_json(options = {})
    super(options.merge(only: %i[id name description tmdb_id]))
  end

  def update_data(data)
    self.name = data[:name] if data[:name]
    self.description = data[:description] if data[:description]
    self.tmdb_id = data[:tmdb_id] if data[:tmdb_id]
  end
end
