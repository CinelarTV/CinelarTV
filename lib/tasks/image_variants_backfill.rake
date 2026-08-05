# frozen_string_literal: true

namespace :image_variants do
  desc "Backfill image_variants from existing banner/cover/thumbnail columns"
  task backfill: :environment do
    puts "=== Image Variants Backfill ==="
    puts ""

    # Phase 1: Create original variants from existing URLs
    puts "Phase 1: Creating original variants from existing data..."
    backfill_contents
    backfill_episodes

    puts ""
    puts "Backfill complete!"
    puts "Tip: To generate all resized variants (thumbnail, small, medium, large, xlarge),"
    puts "     re-upload images through the admin panel or run:"
    puts "     bundle exec rake image_variants:regenerate_all"
  end

  desc "Regenerate all variants for all content (downloads and reprocesses)"
  task regenerate_all: :environment do
    puts "=== Regenerating All Image Variants ==="
    puts ""

    Content.find_each do |content|
      process_content_images(content)
    end

    Episode.find_each do |episode|
      process_episode_images(episode)
    end

    puts "Regeneration complete!"
  end

  desc "Regenerate variants for a single content"
  task :regenerate_content, [:content_id] => :environment do |_t, args|
    content = Content.find(args[:content_id])
    process_content_images(content)
    puts "Done!"
  end

  private

  def backfill_contents
    count = 0
    skipped = 0
    Content.find_each do |content|
      if content[:cover].present?
        content.image_variants.find_or_create_by(
          image_type: "poster", variant: "original", format: "webp"
        ) do |iv|
          iv.url = append_cachebust(content[:cover])
        end
        count += 1
      end

      if content[:banner].present?
        content.image_variants.find_or_create_by(
          image_type: "backdrop", variant: "original", format: "webp"
        ) do |iv|
          iv.url = append_cachebust(content[:banner])
        end
        count += 1
      end

      skipped += 1
      print "."
    end
    puts " #{count} original variants created/updated for Contents (#{skipped} processed)"
  end

  def backfill_episodes
    count = 0
    Episode.find_each do |episode|
      if episode[:thumbnail].present?
        episode.image_variants.find_or_create_by(
          image_type: "episode_thumbnail", variant: "original", format: "webp"
        ) do |iv|
          iv.url = append_cachebust(episode[:thumbnail])
        end
        count += 1
      end
      print "."
    end
    puts " #{count} original variants created/updated for Episodes"
  end

  def process_content_images(content)
    poster_url = content[:cover]
    backdrop_url = content[:banner]

    generate_variants_for(content, "poster", poster_url) if poster_url.present?
    generate_variants_for(content, "backdrop", backdrop_url) if backdrop_url.present?
  end

  def process_episode_images(episode)
    thumbnail_url = episode[:thumbnail]
    generate_variants_for(episode, "episode_thumbnail", thumbnail_url) if thumbnail_url.present?
  end

  def generate_variants_for(model, image_type, original_url)
    puts "Processing #{model.class.name} ##{model.id} #{image_type}..."

    # Clean existing variants
    model.image_variants.where(image_type: image_type).destroy_all

    # Download original to temp file
    temp_file = download_to_temp(original_url)
    return puts "  Failed to download: #{original_url}" unless temp_file

    # Compute store dir
    subfolder = case image_type
                when "poster" then "covers"
                when "backdrop" then "banners"
                when "episode_thumbnail" then "episode_thumbnails"
                else image_type
                end

    store_dir = "uploads/content_images/#{model.class.name.underscore}/#{model.id}/#{subfolder}"

    # Generate all variants
    generator = ImageVariantGenerator.new(
      model: model,
      image_type: image_type,
      source_path: temp_file,
      store_dir: store_dir
    )

    generated = generator.call
    puts "  Generated #{generated.keys.length} variants"

    # Sync legacy columns
    original_url_val = generated.dig("original", "webp")
    medium_url_val = generated.dig("medium", "webp")
    model.send(:sync_legacy_columns, image_type, original_url_val, medium_url_val)
    model.save!

    File.delete(temp_file) if File.exist?(temp_file)
  rescue StandardError => e
    puts "  Error: #{e.message}"
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end

  def download_to_temp(url)
    require "open-uri"

    temp_dir = Rails.root.join("tmp", "uploads")
    FileUtils.mkdir_p(temp_dir)

    ext = File.extname(URI.parse(url).path).delete(".")
    ext = "jpg" if ext.blank?

    temp_file = File.join(temp_dir, "#{SecureRandom.uuid}_backfill.#{ext}")
    URI.open(url) do |downloaded|
      File.open(temp_file, "wb") { |f| f.write(downloaded.read) }
    end

    temp_file
  rescue StandardError => e
    Rails.logger.error("Failed to download #{url}: #{e.message}")
    nil
  end

  def append_cachebust(url)
    separator = url.include?("?") ? "&" : "?"
    "#{url}#{separator}_cb=#{Time.now.to_i}"
  rescue StandardError
    url
  end
end
