# frozen_string_literal: true

class UserSubscription < ApplicationRecord
	belongs_to :user
	has_many :subscription_payments, dependent: :destroy

	scope :active, -> { 
    where("status IN ('active', 'approved') OR (ends_at IS NOT NULL AND ends_at >= ?) OR (granted_until IS NOT NULL AND granted_until >= ?)", 
          Time.zone.now, Time.zone.now)
	}
	scope :by_provider, ->(provider) { where(provider: provider) }

	def active?
		%w[active approved].include?(status.to_s) || 
		(ends_at.present? && ends_at >= Time.zone.now) || 
		(renews_at.present? && renews_at >= Time.zone.now && !%w[unpaid expired].include?(status.to_s)) ||
		(granted_until.present? && granted_until >= Time.zone.now)
	end
end
