# frozen_string_literal: true

class ProviderEvent < ApplicationRecord
  validates :provider_key, :event_type, :payload_sha256, :received_at, presence: true

  scope :unprocessed, -> { where(processed_at: nil) }
end
