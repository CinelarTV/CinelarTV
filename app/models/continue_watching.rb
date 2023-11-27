# frozen_string_literal: true

# app/models/continue_watching.rb

class ContinueWatching < ApplicationRecord
  belongs_to :profile
  belongs_to :content
  belongs_to :episode, optional: true # En el caso de películas, episode_id puede ser nulo

  validates :profile_id, presence: true
end
