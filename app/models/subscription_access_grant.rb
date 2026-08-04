# frozen_string_literal: true

class SubscriptionAccessGrant < ApplicationRecord
  belongs_to :user
  belongs_to :granted_by_user, class_name: "User", optional: true

  after_commit -> { CinelarTV.cache.delete("user_subscribed/#{user_id}") }

  scope :active_at, ->(at = Time.current) { where(revoked_at: nil).where("starts_at <= ? AND ends_at >= ?", at, at) }
end
