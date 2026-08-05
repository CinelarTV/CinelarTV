# frozen_string_literal: true

class ImageVariant < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  IMAGE_TYPES = %w[
    poster backdrop episode_thumbnail
    season_poster collection_artwork logo avatar
  ].freeze

  VARIANTS = %w[original thumbnail small medium large xlarge].freeze

  FORMATS = %w[webp avif].freeze

  validates :image_type, presence: true, inclusion: { in: IMAGE_TYPES }
  validates :variant, presence: true, inclusion: { in: VARIANTS }
  validates :format, presence: true, inclusion: { in: FORMATS }
  validates :url, presence: true

  validates :image_type,
            uniqueness: {
              scope: %i[imageable_type imageable_id variant format],
              message: "variant already exists for this combination"
            }

  scope :for_type, ->(type) { where(image_type: type) }
  scope :for_variant, ->(variant) { where(variant: variant) }
  scope :originals, -> { where(variant: "original") }
end
