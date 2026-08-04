# frozen_string_literal: true

class Subscription < ApplicationRecord
  STATUSES = %w[pending active past_due cancelled expired].freeze

  belongs_to :user
  has_many :payments, dependent: :restrict_with_exception

  after_commit :clear_access_cache

  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }

  scope :open, -> { where(status: %w[pending active past_due cancelled]) }

  def access_active?(at: Time.current)
    access_until.present? && access_until >= at
  end

  def cancellable?
    %w[pending active past_due].include?(status)
  end

  private

  def clear_access_cache
    CinelarTV.cache.delete("user_subscribed/#{user_id}")
  end
end
