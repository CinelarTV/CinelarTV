# frozen_string_literal: true

class Dislike < ApplicationRecord
  belongs_to :profile
  belongs_to :content

  validates :profile_id, :content_id, presence: true
end
