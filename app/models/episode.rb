# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  has_many :video_sources, as: :videoable
  belongs_to :season

  validates :title, presence: true
  validates :description, presence: true

  before_destroy :destroy_video_sources

  def destroy_video_sources
    video_sources.destroy_all
  end
end
