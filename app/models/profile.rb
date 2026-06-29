# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user
  has_many :preferences, dependent: :destroy # Si se elimina un perfil, se eliminan sus preferencias
  has_and_belongs_to_many :liked_contents, class_name: "Content", join_table: "likes"
  has_many :watch_sessions, dependent: :destroy


  # Lista de IDs de avatares por defecto. Úsese como fuente única para el json y validaciones.
  DEFAULT_AVATAR_IDS = %w[coolCat cuteCat dino_boy dino baby_unicorn shy-pigeon little-cow cool-alien].freeze

  def self.default_avatars
    DEFAULT_AVATAR_IDS.map do |id|
      {
        id: id,
        name: id.to_s.tr("_", " ").split.map(&:capitalize).join(" "),
        path: "/assets/default/avatars/#{id}.png"
      }
    end
  end

  def self.valid_avatar_id?(id)
    id.present? && DEFAULT_AVATAR_IDS.include?(id.to_s)
  end


  validate :validate_profile_count, on: :create
  validates :name, presence: true, length: { minimum: 3, maximum: 20 }


  def validate_profile_count
    return unless user && user.profiles.count >= 5

    errors.add(:base, "User can't have more than 5 profiles")
  end
end
