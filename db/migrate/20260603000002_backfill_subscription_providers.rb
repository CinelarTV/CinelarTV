# frozen_string_literal: true

class BackfillSubscriptionProviders < ActiveRecord::Migration[7.2]
  def up
    # Legacy subscriptions (from the LemonSqueezy-only era) have nil or empty
    # provider. Backfill them so Registry.build and provider-specific logic work.
    UserSubscription.where(provider: [nil, ""]).update_all(provider: "lemon_squeezy")
  end

  def down
    # Intentionally blank — cannot reliably reverse which were legacy vs set.
  end
end
