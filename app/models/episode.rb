# frozen_string_literal: true

# app/models/episode.rb
class Episode < ApplicationRecord
  include Videoable

  belongs_to :season
  has_one :content, through: :season

  validates :title, presence: true
  validates :description, presence: true

  before_destroy :delete_associated_continue_watching

  def delete_associated_continue_watching
    ContinueWatching.where(episode_id: id).destroy_all
  end
end
