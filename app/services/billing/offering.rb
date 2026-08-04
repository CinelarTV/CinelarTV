# frozen_string_literal: true

module Billing
  Offering = Data.define(:key, :amount_cents, :currency, :interval_unit, :interval_count) do
    def self.current
      new(
        key: "cinelartv_membership_monthly",
        amount_cents: SiteSetting.subscription_amount_cents.to_i,
        currency: SiteSetting.subscription_currency.to_s.upcase,
        interval_unit: SiteSetting.subscription_interval_unit.to_s,
        interval_count: SiteSetting.subscription_interval_count.to_i
      )
    end

    def amount
      amount_cents / 100.0
    end
  end
end
