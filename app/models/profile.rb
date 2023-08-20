# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user
  has_many :preferences, dependent: :destroy # Si se elimina un perfil, se eliminan sus preferencias
  

  validate :validate_profile_count, on: :create


  def validate_profile_count
    return unless user && user.profiles.count >= 5

    errors.add(:base, "User can't have more than 5 profiles")
  end
end
