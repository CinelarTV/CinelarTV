# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  has_many :video_sources, as: :videoable
  belongs_to :season

  validates :title, presence: true
  validates :description, presence: true

  before_destroy :destroy_video_sources
  before_destroy :delete_associated_continue_watching

  def destroy_video_sources
    video_sources.destroy_all
  end

  def delete_associated_continue_watching
    ContinueWatching.where(episode_id: id).destroy_all
  end
end
