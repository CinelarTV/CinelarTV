# frozen_string_literal: true

class ImageProcessingJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 2

  def perform(model_class, model_id, image_type, temp_file_path)
    unless File.exist?(temp_file_path)
      Rails.logger.error("ImageProcessingJob: temp file missing: #{temp_file_path}")
      return
    end

    model = model_class.constantize.find(model_id)
    image_type_str = image_type.to_s

    # Clean up existing variants for this image type
    model.image_variants.where(image_type: image_type_str).destroy_all

    # Clean up old files
    cleanup_old_files(model, image_type_str)

    # Compute store directory
    store_dir = compute_store_dir(model, image_type_str)

    # Generate all variants (original + thumbnail/small/medium/large/xlarge × avif/webp)
    generator = ImageVariantGenerator.new(
      model: model,
      image_type: image_type_str,
      source_path: temp_file_path,
      store_dir: store_dir
    )

    generated = generator.call

    # Sync legacy columns for backward compatibility
    original_url = generated.dig("original", "webp")
    medium_url = generated.dig("medium", "webp")
    model.send(:sync_legacy_columns, image_type_str, original_url, medium_url)
    model.save!

    cleanup_temp_file(temp_file_path)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("ImageProcessingJob: record not found: #{e.message}")
    cleanup_temp_file(temp_file_path)
  rescue StandardError => e
    Rails.logger.error("ImageProcessingJob failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise e
  end

  private

  def compute_store_dir(model, image_type)
    model_name = model.class.name.underscore

    subfolder = case image_type
                when "poster" then "covers"
                when "backdrop" then "banners"
                when "episode_thumbnail" then "episode_thumbnails"
                when "logo" then "logos"
                else image_type
                end

    "uploads/content_images/#{model_name}/#{model.id}/#{subfolder}"
  end

  def cleanup_old_files(model, image_type)
    subfolder = case image_type
                when "poster" then "covers"
                when "backdrop" then "banners"
                when "episode_thumbnail" then "episode_thumbnails"
                when "logo" then "logos"
                else image_type
                end

    model_name = model.class.name.underscore
    store_dir = "uploads/content_images/#{model_name}/#{model.id}/#{subfolder}"

    old_variants = model.image_variants.where(image_type: image_type)
    return if old_variants.empty?

    ImageStorageService.cleanup_dir(store_dir) if SiteSetting.storage_provider == "local"
    old_variants.destroy_all
  end

  def cleanup_temp_file(path)
    FileUtils.rm_f(path)
  rescue StandardError => e
    Rails.logger.warn("Failed to delete temp file #{path}: #{e.message}")
  end
end
