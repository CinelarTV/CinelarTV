# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :cast_members, dependent: :destroy
  has_many :contents, through: :cast_members

  validates :tmdb_id, uniqueness: true, allow_nil: true
  validates :name, presence: true

  def as_json(options = {})
    super(options.merge(only: %i[id tmdb_id name profile_path known_for_department]))
  end
end
