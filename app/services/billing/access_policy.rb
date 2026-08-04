# frozen_string_literal: true

module Billing
  class AccessPolicy
    def self.active?(user, at: Time.current)
      Subscription.where(user: user).where("access_until >= ?", at).exists? ||
        SubscriptionAccessGrant.where(user: user).active_at(at).exists?
    end
  end
end
