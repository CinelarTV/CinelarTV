# frozen_string_literal: true

require "aws-sdk-s3"

class ImageStorageService
  VARIANTS = {
    "original" => nil,
    "thumbnail" => [320, 180],
    "small" => [480, 270],
    "medium" => [800, 450],
    "large" => [1280, 720],
    "xlarge" => [1920, 1080]
  }.freeze

  QUALITY = {
    "avif" => 70,
    "webp" => 80
  }.freeze

  # Store a single image file, returning the public URL
  def self.store(source_path, store_dir:, filename:)
    if SiteSetting.storage_provider == "s3"
      store_to_s3(source_path, store_dir, filename)
    else
      store_locally(source_path, store_dir, filename)
    end
  end

  # Clean up all files under a directory
  def self.cleanup_dir(store_dir)
    if SiteSetting.storage_provider == "s3"
      cleanup_s3_dir(store_dir)
    else
      cleanup_local_dir(store_dir)
    end
  rescue StandardError => e
    Rails.logger.warn("ImageStorageService cleanup failed: #{e.message}")
  end

  def self.store_locally(source_path, store_dir, filename)
    target = Rails.root.join("public", store_dir, filename)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(source_path, target)
    "/#{store_dir}/#{filename}"
  end

  def self.store_to_s3(source_path, store_dir, filename)
    s3_client = build_s3_client
    bucket = SiteSetting.s3_bucket
    s3_key = "#{store_dir}/#{filename}"

    File.open(source_path, "rb") do |file|
      s3_client.put_object(
        bucket: bucket,
        key: s3_key,
        body: file,
        acl: "public-read",
        content_type: content_type_for(filename)
      )
    end

    build_public_url(s3_key)
  end

  def self.build_s3_client
    Aws::S3::Client.new(
      access_key_id: SiteSetting.s3_access_key_id,
      secret_access_key: SiteSetting.s3_secret_access_key,
      region: SiteSetting.s3_region || "us-east-1",
      endpoint: SiteSetting.s3_endpoint.presence
    )
  end

  def self.build_public_url(s3_key)
    bucket = SiteSetting.s3_bucket

    if SiteSetting.cdn_enabled && SiteSetting.cdn_url.present?
      "#{SiteSetting.cdn_url}/#{s3_key}"
    elsif SiteSetting.s3_endpoint.present?
      "#{SiteSetting.s3_endpoint}/#{bucket}/#{s3_key}"
    else
      "https://#{bucket}.s3.#{SiteSetting.s3_region || 'us-east-1'}.amazonaws.com/#{s3_key}"
    end
  end

  def self.content_type_for(filename)
    case File.extname(filename).downcase
    when ".avif" then "image/avif"
    when ".webp" then "image/webp"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    else "application/octet-stream"
    end
  end

  def self.cleanup_local_dir(store_dir)
    full_path = Rails.root.join("public", store_dir)
    FileUtils.rm_rf(full_path)
  end

  def self.cleanup_s3_dir(store_dir)
    s3_client = build_s3_client
    bucket = SiteSetting.s3_bucket

    response = s3_client.list_objects_v2(bucket: bucket, prefix: store_dir)
    return unless response.contents.any?

    s3_client.delete_objects(
      bucket: bucket,
      delete: { objects: response.contents.map { |obj| { key: obj.key } } }
    )
  end
end
