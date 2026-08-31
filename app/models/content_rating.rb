# frozen_string_literal: true

class ContentRating < ApplicationRecord
  has_many :contents
  has_many :episodes

  validates :code, presence: true, uniqueness: true
  validates :system, presence: true
  validates :name_translations, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:min_age) }

  def name_for(locale = I18n.locale)
    name_translations[locale.to_s] || name_translations["en"] || code
  end

  def description_for(locale = I18n.locale)
    description_translations[locale.to_s] || description_translations["en"] || ""
  end

  def as_json_with_locale(locale: I18n.locale)
    {
      code: code,
      system: system,
      name: name_for(locale),
      description: description_for(locale),
      min_age: min_age,
      color: color
    }
  end

  def to_s
    name_for
  end
end
