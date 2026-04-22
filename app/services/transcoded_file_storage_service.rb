# frozen_string_literal: true

require 'aws-sdk-s3'

class TranscodedFileStorageService
  def self.store_transcoded_files(source_dir, video_source)
    storage_provider = SiteSetting.storage_provider

    case storage_provider
    when 'local'
      store_locally(source_dir, video_source)
    when 's3'
      store_to_s3(source_dir, video_source)
    else
      Rails.logger.error "Unsupported storage provider: #{storage_provider}"
      { success: false, error: "Unsupported storage provider" }
    end
  end

  def self.cleanup_transcoded_files(video_source)
    storage_provider = SiteSetting.storage_provider

    case storage_provider
    when 'local'
      cleanup_local(video_source)
    when 's3'
      cleanup_s3(video_source)
    end
  rescue StandardError => e
    Rails.logger.error "Error cleaning up transcoded files: #{e.message}"
  end

  private

  def self.store_locally(source_dir, video_source)
    videoable_id = video_source.videoable_id
    target_dir = Rails.root.join('public', 'content-media', videoable_id.to_s)
    FileUtils.mkdir_p(target_dir)

    # Copy all files from source to target
    Dir.glob(File.join(source_dir, '*')).each do |file|
      FileUtils.cp(file, target_dir)
    end

    # Clean up source directory
    FileUtils.rm_rf(source_dir)

    # Build base URL with site base URL
    base_path = "/content-media/#{videoable_id}"
    base_url = "#{SiteSetting.base_url}#{base_path}"

    { success: true, base_url: base_url }
  rescue StandardError => e
    Rails.logger.error "Error storing transcoded files locally: #{e.message}"
    { success: false, error: e.message }
  end

  def self.store_to_s3(source_dir, video_source)
    videoable_id = video_source.videoable_id
    s3_client = Aws::S3::Client.new(
      access_key_id: SiteSetting.s3_access_key_id,
      secret_access_key: SiteSetting.s3_secret_access_key,
      region: SiteSetting.s3_region || 'us-east-1',
      endpoint: SiteSetting.s3_endpoint
    )

    bucket = SiteSetting.s3_bucket
    base_path = "content-media/#{videoable_id}"

    uploaded_files = []

    # Upload all files from source directory to S3
    Dir.glob(File.join(source_dir, '*')).each do |file|
      filename = File.basename(file)
      s3_key = "#{base_path}/#{filename}"

      s3_client.put_object(
        bucket: bucket,
        key: s3_key,
        body: File.open(file),
        acl: 'public-read'
      )

      uploaded_files << filename
    end

    # Clean up local source directory after successful S3 upload
    FileUtils.rm_rf(source_dir)

    # Build base URL
    cdn_url = SiteSetting.cdn_enabled ? SiteSetting.cdn_url : nil
    base_url = if cdn_url
                 "#{cdn_url}/#{base_path}"
               else
                 "https://#{bucket}.s3.#{SiteSetting.s3_region}.amazonaws.com/#{base_path}"
               end

    { success: true, base_url: base_url }
  rescue StandardError => e
    Rails.logger.error "Error storing transcoded files to S3: #{e.message}"
    { success: false, error: e.message }
  end

  def self.cleanup_local(video_source)
    videoable_id = video_source.videoable_id
    target_dir = Rails.root.join('public', 'content-media', videoable_id.to_s)

    if Dir.exist?(target_dir)
      FileUtils.rm_rf(target_dir)
      Rails.logger.info "Cleaned up local transcoded files for videoable #{videoable_id}"
    end
  end

  def self.cleanup_s3(video_source)
    videoable_id = video_source.videoable_id
    s3_client = Aws::S3::Client.new(
      access_key_id: SiteSetting.s3_access_key_id,
      secret_access_key: SiteSetting.s3_secret_access_key,
      region: SiteSetting.s3_region || 'us-east-1',
      endpoint: SiteSetting.s3_endpoint
    )

    bucket = SiteSetting.s3_bucket
    base_path = "content-media/#{videoable_id}"

    # List all objects in the path
    response = s3_client.list_objects_v2(bucket: bucket, prefix: base_path)

    if response.contents.any?
      # Delete all objects
      s3_client.delete_objects(
        bucket: bucket,
        delete: {
          objects: response.contents.map { |obj| { key: obj.key } }
        }
      )
      Rails.logger.info "Cleaned up S3 transcoded files for videoable #{videoable_id}"
    end
  rescue StandardError => e
    Rails.logger.error "Error cleaning up S3 transcoded files: #{e.message}"
  end
end
