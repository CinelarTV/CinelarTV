# frozen_string_literal: true

class Payment < ApplicationRecord
  STATUSES = %w[pending succeeded failed refunded disputed].freeze
  KINDS = %w[initial renewal adjustment refund].freeze

  belongs_to :subscription
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: KINDS }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
end
