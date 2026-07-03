# frozen_string_literal: true

class ImageProcessingJob
  include Sidekiq::Job

  def perform(model_class, model_id, image_type, temp_file_path)
    unless File.exist?(temp_file_path)
      Rails.logger.error("ImageProcessingJob: temp file missing, skipping: #{temp_file_path}")
      return
    end

    model = model_class.constantize.find(model_id)
    image_type_sym = image_type.to_sym
    uploader = ContentImageUploader.new(model, nil, type: image_type_sym)

    # Ensure store directory exists
    store_path = Rails.root.join("public", uploader.store_dir)
    FileUtils.mkdir_p(store_path)

    # Clean up old image if it exists
    cleanup_old_image(model, image_type_sym)

    # Store the new image
    file = File.open(temp_file_path)
    uploader.store!(file)
    file.close

    # Update the model with the new URL and timestamp
    timestamp = Time.now.to_i
    url_with_timestamp = "#{uploader.url}?t=#{timestamp}"
    model.send("#{image_type}=", url_with_timestamp)

    # Store the resized image URL with timestamp
    resized_url_with_timestamp = "#{uploader.resized_image.url}?t=#{timestamp}"
    model.send("#{image_type}_resized=", resized_url_with_timestamp)

    model.save!

    # Clean up temp file
    cleanup_temp_file(temp_file_path)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("ImageProcessingJob: record not found, not retrying: #{e.message}")
    cleanup_temp_file(temp_file_path)
  rescue StandardError => e
    Rails.logger.error("ImageProcessingJob failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise e
  end

  def cleanup_temp_file(temp_file_path)
    File.delete(temp_file_path) if File.exist?(temp_file_path)
  rescue Errno::EACCES, Errno::EBUSY, StandardError => e
    # File might still be locked on Windows or other error
    # Not critical - temp files can be cleaned up later
    Rails.logger.warn("Failed to delete temp file #{temp_file_path}: #{e.message}")
  end

  private

  def cleanup_old_image(model, image_type)
    old_url = model.send(image_type)
    return unless old_url.present?

    # Extract the filename without query parameters
    url_without_query = old_url.split("?").first
    old_filename = url_without_query.split("/").last

    # Determine the subfolder based on image_type
    subfolder = case image_type
                when :banner then "banners"
                when :cover then "covers"
                when :thumbnail then "episode_thumbnails"
                else "other"
                end

    # Handle both local and S3 storage
    if SiteSetting.storage_provider == "local"
      # Local storage cleanup
      store_dir = Rails.root.join("public", "uploads", "content_images", subfolder, old_filename)
      File.delete(store_dir) if File.exist?(store_dir)

      # Clean up resized version
      resized_path = Rails.root.join("public", "uploads", "content_images", subfolder, "resized_image", old_filename)
      File.delete(resized_path) if File.exist?(resized_path)
    else
      # S3 storage cleanup - rely on overwrite for now
      Rails.logger.info("S3 storage detected - old image cleanup skipped (relying on overwrite)")
    end

    # Clear the resized URL field
    model.send("#{image_type}_resized=", nil)
  end
end
