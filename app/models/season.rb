# frozen_string_literal: true

# app/models/season.rb
class Season < ApplicationRecord
  belongs_to :content
  has_many :episodes

  validates :title, presence: true
  validates :tmdb_id, uniqueness: true, allow_nil: true

  before_destroy :delete_episodes

  def as_json(options = {})
    super(options.merge(only: %i[id title description position tmdb_id]))
  end

  private

  def delete_episodes
    episodes.destroy_all
  end
end
