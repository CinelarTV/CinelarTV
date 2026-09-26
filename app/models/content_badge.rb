# frozen_string_literal: true

class ContentBadge < ApplicationRecord
  belongs_to :content

  validates :badge_type, presence: true, inclusion: { in: %w[programming prestige availability] }
  validates :label, presence: true

  scope :active, -> { where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_type, ->(type) { where(badge_type: type) }
  scope :ordered, -> { order(:position) }

  before_save :deactivate_if_expired

  private

  def deactivate_if_expired
    return unless expires_at.present? && expires_at <= Time.current

    self.active = false
  end
end
