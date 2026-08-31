# frozen_string_literal: true

class ContentDescriptor < ApplicationRecord
  has_many :content_content_descriptors, dependent: :destroy
  has_many :contents, through: :content_content_descriptors
  has_many :episode_content_descriptors, dependent: :destroy
  has_many :episodes, through: :episode_content_descriptors

  validates :key, presence: true, uniqueness: true
  validates :name_translations, presence: true
  validates :category, presence: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :ordered, -> { order(:category, :severity_level) }

  def name_for(locale = I18n.locale)
    name_translations[locale.to_s] || name_translations["en"] || key
  end

  def description_for(locale = I18n.locale)
    description_translations[locale.to_s] || description_translations["en"] || ""
  end

  def as_json_with_locale(locale: I18n.locale)
    {
      key: key,
      name: name_for(locale),
      description: description_for(locale),
      category: category,
      severity_level: severity_level
    }
  end

  def to_s
    name_for
  end
end
