# frozen_string_literal: true

class ContentImageUploader < BaseUploader
  MAX_FILE_SIZE = 5.megabytes
  STORE_DIRECTORY = "uploads/content_images"
  EXTENSION_ALLOWLIST = %w[png jpg jpeg].freeze
  IMAGE_TYPE_ALLOWLIST = %i[png jpg jpeg].freeze
  CONTENT_TYPE_ALLOWLIST = %w[image/png image/jpg image/jpeg].freeze

  def initialize(*args, type: nil, **kwargs)
    super(*args)
    @image_type = type # :banner o :cover
  end

  def store_dir
    subfolder = case @image_type
                when :banner then "banners"
                when :cover then "covers"
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
    prefix = @image_type ? @image_type.to_s : "content_image"
    "#{prefix}_#{random_string}.#{file.extension}"
  end

  version :resized_image do
    process resize_to_limit: [800, nil]

    def full_filename(_for_file = file)
      "resized_#{@image_type || "content_image"}_#{random_string}.#{file.extension}"
    end
  end

  private

  def random_string
    SecureRandom.alphanumeric(20)
  end
end
