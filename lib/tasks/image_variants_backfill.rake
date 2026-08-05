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
    puts "(s = skipped, already complete)"
    puts ""

    processed = 0
    skipped = 0

    Content.find_each do |content|
      result = process_content_images(content)
      processed += 1 if result
      skipped += 1 unless result
    end

    Episode.find_each do |episode|
      result = process_episode_images(episode)
      processed += 1 if result
      skipped += 1 unless result
    end

    puts ""
    puts "Done! Processed: #{processed}, Skipped: #{skipped}"
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

    poster_done = poster_url.present? ? generate_variants_for(content, "poster", poster_url) : false
    backdrop_done = backdrop_url.present? ? generate_variants_for(content, "backdrop", backdrop_url) : false

    poster_done || backdrop_done
  end

  def process_episode_images(episode)
    thumbnail_url = episode[:thumbnail]
    thumbnail_url.present? ? generate_variants_for(episode, "episode_thumbnail", thumbnail_url) : false
  end

  # Standard image types: 6 variants × 2 formats = 12
  # Logo: 3 variants × 1 format = 3
  EXPECTED_VARIANT_COUNTS = {
    "poster" => 12,
    "backdrop" => 12,
    "episode_thumbnail" => 12,
    "logo" => 3
  }.freeze

  def generate_variants_for(model, image_type, original_url)
    expected = EXPECTED_VARIANT_COUNTS[image_type] || 12
    current_count = model.image_variants.where(image_type: image_type).count

    if current_count >= expected
      print "s" # skip
      return false
    end

    puts "Processing #{model.class.name} ##{model.id} #{image_type} (#{current_count}/#{expected} variants)..."

    # Clean existing variants
    model.image_variants.where(image_type: image_type).destroy_all

    # Download original to temp file
    temp_file = download_to_temp(original_url)
    unless temp_file
      puts "  Failed to download: #{original_url}"
      return false
    end

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
    true
  rescue StandardError => e
    puts "  Error: #{e.message}"
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
    false
  end

  def download_to_temp(url)
    require "open-uri"

    temp_dir = Rails.root.join("tmp", "uploads")
    FileUtils.mkdir_p(temp_dir)

    # Strip query params (?t=..., ?_cb=...) — local paths don't use them
    clean_path = url.split("?").first
    ext = File.extname(clean_path).delete(".")
    ext = "jpg" if ext.blank?

    temp_file = File.join(temp_dir, "#{SecureRandom.uuid}_backfill.#{ext}")

    if clean_path.start_with?("http://", "https://")
      # Remote URL — download via HTTP
      URI.open(clean_path) do |downloaded|
        File.open(temp_file, "wb") { |f| f.write(downloaded.read) }
      end
    else
      # Local path — resolve against public/
      full_path = clean_path.start_with?("/") ? Rails.root.join("public", clean_path.sub(/\A\//, "")) : Rails.root.join("public", clean_path)

      unless File.exist?(full_path)
        Rails.logger.error("File not found: #{full_path} (original url: #{url})")
        return nil
      end

      FileUtils.cp(full_path, temp_file)
    end

    temp_file
  rescue StandardError => e
    Rails.logger.error("Failed to read #{url}: #{e.message}")
    nil
  end

  def append_cachebust(url)
    separator = url.include?("?") ? "&" : "?"
    "#{url}#{separator}_cb=#{Time.now.to_i}"
  rescue StandardError
    url
  end
end
