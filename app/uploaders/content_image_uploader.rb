# frozen_string_literal: true

class ContentImageUploader < BaseUploader
  MAX_FILE_SIZE = 5.megabytes
  STORE_DIRECTORY = "uploads/content_images"
  EXTENSION_ALLOWLIST = %w[png jpg jpeg webp].freeze
  IMAGE_TYPE_ALLOWLIST = %i[png jpg jpeg webp].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/png image/jpg image/jpeg image/webp].freeze

  def initialize(model = nil, mounted_as = nil, type: nil, **kwargs)
    super(model, mounted_as)
    @image_type = type # :banner, :cover, :episode_thumbnail
  end

  def store_dir
    subfolder = case @image_type
                when :banner then "banners"
                when :cover then "covers"
                when :episode_thumbnail then "episode_thumbnails"
                else "other"
                end
    File.join(STORE_DIRECTORY, subfolder)
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def image_type_whitelist
    IMAGE_TYPE_ALLOWLIST
  end

  def size_range
    1..MAX_FILE_SIZE
  end

  def content_type_allowlist
    CONTENT_TYPE_ALLOWLIST
  end

  def filename
    return nil unless model

    "#{model.id}.webp"
  end

  # Convert to WebP with specified quality
  process convert_to_webp: [:file]

  version :resized_image do
    process resize_to_limit: [800, nil]
    process convert_to_webp: [:file]

    def full_filename(_for_file = file)
      "#{model.id}.webp" if model
    end
  end

  private

  def convert_to_webp(file)
    return unless file

    quality = SiteSetting.image_uploads_quality || 85

    manipulate! do |img|
      img.format("webp")
      img.quality(quality)
      img
    end
  end
end
