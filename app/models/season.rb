# frozen_string_literal: true

# app/models/season.rb
class Season < ApplicationRecord
  belongs_to :content, touch: true
  has_many :episodes, dependent: :destroy

  after_commit :touch_content, on: %i[create update destroy]

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

  def touch_content
    content&.touch
  end
end
