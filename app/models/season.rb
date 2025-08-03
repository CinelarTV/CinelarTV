# frozen_string_literal: true

# app/models/season.rb
class Season < ApplicationRecord
  belongs_to :content
  has_many :episodes

  validates :title, presence: true

  before_destroy :delete_episodes

  private

  def delete_episodes
    episodes.destroy_all
  end
end
