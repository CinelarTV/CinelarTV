# frozen_string_literal: true

require 'aws-sdk-s3'

module FileStore
  class S3Store < BaseStore
    def initialize
      @s3_client = build_s3_client
      @bucket = SiteSetting.s3_bucket
    end

    def store_file(file, path)
      s3_key = "uploads/#{path}"

      @s3_client.put_object(
        bucket: @bucket,
        key: s3_key,
        body: file.read,
        acl: 'public-read'
      )

      build_url(s3_key)
    rescue StandardError => e
      Rails.logger.error "Error storing file to S3: #{e.message}"
      raise DownloadError, "Failed to store file: #{e.message}"
    end

    def delete_file(path)
      s3_key = "uploads/#{path}"

      @s3_client.delete_object(
        bucket: @bucket,
        key: s3_key
      )
    rescue StandardError => e
      Rails.logger.error "Error deleting file from S3: #{e.message}"
    end

    def download_file(path)
      s3_key = "uploads/#{path}"

      response = @s3_client.get_object(
        bucket: @bucket,
        key: s3_key
      )

      response.body
    rescue Aws::S3::Errors::NoSuchKey => e
      Rails.logger.error "File not found in S3: #{e.message}"
      raise DownloadError, "File not found"
    rescue StandardError => e
      Rails.logger.error "Error downloading file from S3: #{e.message}"
      raise DownloadError, "Failed to download file: #{e.message}"
    end

    def external?
      true # S3Store always stores files externally
    end

    private

    def build_s3_client
      Aws::S3::Client.new(
        access_key_id: SiteSetting.s3_access_key_id,
        secret_access_key: SiteSetting.s3_secret_access_key,
        region: SiteSetting.s3_region || 'us-east-1',
        endpoint: build_endpoint
      )
    end

    def build_endpoint
      endpoint = SiteSetting.s3_endpoint
      return nil if endpoint.blank?

      endpoint
    end

    def build_url(s3_key)
      # Priority: CDN URL > S3 Endpoint > AWS Standard
      if SiteSetting.cdn_enabled && SiteSetting.cdn_url.present?
        "#{SiteSetting.cdn_url}/#{s3_key}"
      elsif SiteSetting.s3_endpoint.present?
        "#{SiteSetting.s3_endpoint}/#{@bucket}/#{s3_key}"
      else
        # AWS standard endpoint
        "https://#{@bucket}.s3.#{SiteSetting.s3_region || 'us-east-1'}.amazonaws.com/#{s3_key}"
      end
    end
  end
end
