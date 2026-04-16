# frozen_string_literal: true

class SubscriptionPayment < ApplicationRecord
  belongs_to :user
  belongs_to :user_subscription

  validates :provider, presence: true
  validates :provider_payment_id, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :status, presence: true

  # Ensure we don't duplicate transactions for the same provider and payment id
  validates :provider_payment_id, uniqueness: { scope: :provider }
end
