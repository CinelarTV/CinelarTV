# frozen_string_literal: true

class UserSubscription < ApplicationRecord
	belongs_to :user

	scope :active, -> { where(status: %w[active approved]) }
	scope :by_provider, ->(provider) { where(provider: provider) }

	def active?
		%w[active approved].include?(status.to_s)
	end
end
