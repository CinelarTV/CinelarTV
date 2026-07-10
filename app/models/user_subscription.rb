# frozen_string_literal: true

class UserSubscription < ApplicationRecord
  belongs_to :user
  has_many :subscription_payments, dependent: :destroy

  after_commit :clear_subscription_cache

  # Canonical statuses: active, trialing, pending, past_due, cancelled, expired, granted
  ACTIVE_STATUSES = %w[active trialing approved].freeze
  INACTIVE_STATUSES = %w[cancelled canceled rejected expired unpaid].freeze

  scope :active, -> {
    where(status: ACTIVE_STATUSES)
      .or(where("ends_at IS NOT NULL AND ends_at >= ?", Time.zone.now))
      .or(where("granted_until IS NOT NULL AND granted_until >= ?", Time.zone.now))
  }
  scope :by_provider, ->(provider) { where(provider: provider) }

  def active?
    return true if ACTIVE_STATUSES.include?(status.to_s)
    return true if ends_at.present? && ends_at >= Time.zone.now
    return true if granted_until.present? && granted_until >= Time.zone.now
    false
  end

  def trialing?
    status.to_s == "trialing" && trial_ends_at.present? && trial_ends_at >= Time.zone.now
  end

  private

  def clear_subscription_cache
    CinelarTV.cache.delete("user_subscribed/#{user_id}")
  end
end
