# frozen_string_literal: true

class EmailTemplate < ApplicationRecord
  validates :key, presence: true
  validates :locale, presence: true
  validates :key, uniqueness: { scope: :locale }

  scope :for_key_and_locale, ->(key, locale) { where(key:, locale:) }
  scope :for_key, ->(key) { where(key:) }
end
