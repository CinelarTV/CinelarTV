# frozen_string_literal: true

class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter
  include CarrierWave::MiniMagick
  require "aws-sdk-s3"

  # Choose what kind of storage to use for this uploader based on SiteSetting, and fall back to file
  # storage if nothing is set. This is useful for development and testing.
  def self.configure_storage
    if SiteSetting.storage_provider == "local"
      Rails.logger.info("Using local file storage for uploads")
      storage :file
    else
      Rails.logger.info("Using S3 for uploads")
      storage :aws
      # Set the endpoint to the SiteSetting if it exists, otherwise use the default endpoint for the region
      @endpoint = SiteSetting.s3_endpoint.presence || "https://s3.#{SiteSetting.s3_region}.amazonaws.com"
      configure do |config|
        config.aws_credentials = {
          access_key_id: SiteSetting.s3_access_key_id,
          secret_access_key: SiteSetting.s3_secret_access_key,
          region: SiteSetting.s3_region,
          endpoint: @endpoint,
        }
        config.aws_bucket = SiteSetting.s3_bucket
        config.aws_acl = "public-read"
      end
    end
  end

  EXTENSION_ALLOWLIST = %w[jpg jpeg jpe gif png ico bmp dng].freeze
  FRAME_MAX = 500
  FRAME_STRIP_MAX = 150

  process :validate_frame_count
  process :strip_exif

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def size_range
    1..(25.megabytes)
  end

  protected

  def strip_exif
    return if file.content_type.include?("svg")

    manipulate! do |image|
      image.strip unless image.frames.count > FRAME_STRIP_MAX
      image = yield(image) if block_given?
      image
    end
  end

  def validate_frame_count
    begin
      return unless MiniMagick::Image.new(file.path).frames.count > FRAME_MAX
    rescue Timeout::Error
      raise CarrierWave::IntegrityError, "Image processing timed out."
    end

    raise CarrierWave::IntegrityError, "GIF contains too many frames. Max frame count allowed is #{FRAME_MAX}."
  end

  private

  configure_storage
end
