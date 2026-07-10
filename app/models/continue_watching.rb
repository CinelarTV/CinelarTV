# frozen_string_literal: true

# app/models/continue_watching.rb

class ContinueWatching < ApplicationRecord
  belongs_to :profile
  belongs_to :content
  belongs_to :episode, optional: true # En el caso de películas, episode_id puede ser nulo

  validates :profile_id, presence: true

  def progress
    episode_key = episode_id.presence || 'movie'
    cached = Rails.cache.read("progress/#{profile_id}/#{content_id}/#{episode_key}")
    cached ? cached[:progress] : super
  end
end
