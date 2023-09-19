# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  has_many :video_sources, as: :videoable
  belongs_to :season

  validates :title, presence: true
  validates :description, presence: true
end
