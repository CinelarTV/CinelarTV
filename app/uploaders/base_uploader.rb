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
      Rails.logger.info("Using S3-compatible storage for uploads")
      storage :aws

      # Build endpoint (empty for AWS standard, custom for S3-compatible services)
      endpoint = SiteSetting.s3_endpoint.presence

      # Build asset_host with priority: CDN URL > S3 Endpoint > nil (AWS standard)
      asset_host = build_asset_host

      configure do |config|
        config.aws_credentials = {
          access_key_id: SiteSetting.s3_access_key_id,
          secret_access_key: SiteSetting.s3_secret_access_key,
          region: SiteSetting.s3_region || "us-east-1",
          endpoint: endpoint
        }
        config.aws_bucket = SiteSetting.s3_bucket || "cinelartv"
        config.aws_acl = "public-read"
        config.asset_host = asset_host
      end
    end
  end

  EXTENSION_ALLOWLIST = %w[jpg jpeg jpe gif png ico bmp dng webp].freeze
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

  def self.build_asset_host
    # Priority: CDN URL > S3 Endpoint > nil (AWS standard)
    if SiteSetting.cdn_enabled && SiteSetting.cdn_url.present?
      SiteSetting.cdn_url
    elsif SiteSetting.s3_endpoint.present?
      SiteSetting.s3_endpoint
    else
      nil # Let carrierwave-aws use AWS standard endpoint
    end
  end

  configure_storage
end
