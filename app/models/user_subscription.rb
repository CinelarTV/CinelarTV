# frozen_string_literal: true

class UserSubscription < ApplicationRecord
	belongs_to :user

	scope :active, -> { where(status: %w[active approved]) }
	scope :by_provider, ->(provider) { where(provider: provider) }

	def active?
		%w[active approved].include?(status.to_s) || 
		(ends_at.present? && ends_at >= Time.zone.now) || 
		(renews_at.present? && renews_at >= Time.zone.now && !%w[unpaid expired].include?(status.to_s)) ||
		(granted_until.present? && granted_until >= Time.zone.now)
	end
end
