# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  belongs_to :season

  validates :title, presence: true
  validates :description, presence: true
end
