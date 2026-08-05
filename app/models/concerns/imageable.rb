# frozen_string_literal: true

module Imageable
  extend ActiveSupport::Concern

  included do
    has_many :image_variants, as: :imageable, dependent: :destroy
  end

  # Get a specific image URL.
  # Uses preloaded image_variants when available (N+1 safe).
  #
  #   content.image_url_for("poster", variant: "thumbnail", format: "avif")
  #   content.image_url_for("backdrop")  # original webp by default
  #
  def image_url_for(image_type, variant: "original", format: "webp")
    if image_variants.loaded?
      image_variants.find { |v|
        v.image_type == image_type.to_s && v.variant == variant.to_s && v.format == format.to_s
      }&.url
    else
      image_variants
        .find_by(image_type: image_type, variant: variant, format: format)
        &.url
    end
  end

  # Get all variants for a given image type as a nested hash.
  # Uses preloaded image_variants when available (N+1 safe).
  #
  #   content.image_variants_for("poster")
  #   # => {
  #   #   "original"  => { "webp" => "https://..." },
  #   #   "thumbnail" => { "avif" => "https://...", "webp" => "https://..." },
  #   #   ...
  #   # }
  #
  def image_variants_for(image_type, only: nil)
    # Use preloaded association when available (avoids N+1)
    variants = if image_variants.loaded?
                 image_variants.select { |v| v.image_type == image_type.to_s }
               else
                 image_variants.where(image_type: image_type)
               end

    grouped = variants
              .sort_by(&:variant)
              .group_by(&:variant)
              .transform_values do |vars|
      vars.each_with_object({}) { |v, h| h[v.format] = v.url }
    end

    return grouped unless only

    allowed = Array(only).map(&:to_s)
    grouped.slice(*allowed)
  end

  # Legacy accessor: poster original URL
  def poster_url
    image_url_for("poster")
  end

  # Legacy accessor: backdrop original URL
  def backdrop_url
    image_url_for("backdrop")
  end

  # Legacy accessor: logo original URL
  def logo_url
    image_url_for("logo")
  end

  # Delete all image variants for this model
  def destroy_all_images
    image_variants.destroy_all
  end

  private

  # Sync legacy columns after generating variants
  def sync_legacy_columns(image_type, original_url, resized_url = nil)
    case image_type.to_s
    when "poster"
      self[:cover] = original_url
      self[:cover_resized] = resized_url if respond_to?(:cover_resized=)
    when "backdrop"
      self[:banner] = original_url
      self[:banner_resized] = resized_url if respond_to?(:banner_resized=)
    when "episode_thumbnail"
      self[:thumbnail] = original_url
      self[:thumbnail_resized] = resized_url if respond_to?(:thumbnail_resized=)
    end
  end
end
