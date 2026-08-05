# frozen_string_literal: true

require "mini_magick"

class ImageVariantGenerator
  VARIANTS = {
    "original" => nil,
    "thumbnail" => [320, 180],
    "small" => [480, 270],
    "medium" => [800, 450],
    "large" => [1280, 720],
    "xlarge" => [1920, 1080]
  }.freeze

  LOGO_VARIANTS = {
    "original" => nil,
    "small" => 480,
    "medium" => 800
  }.freeze

  FORMATS = %w[avif webp].freeze

  LOGO_FORMATS = %w[webp].freeze

  def initialize(model:, image_type:, source_path:, store_dir:)
    @model = model
    @image_type = image_type
    @source_path = source_path
    @store_dir = store_dir
  end

  def call
    if logo?
      generate_logo_variants
    else
      generate_standard_variants
    end
  end

  private

  def logo?
    @image_type.to_s == "logo"
  end

  def generate_standard_variants
    generated = {}

    VARIANTS.each do |variant_name, dimensions|
      generated[variant_name] = {}

      FORMATS.each do |format_name|
        filename = "#{variant_name}.#{format_name}"
        tmp_output = Tempfile.new([variant_name, ".#{format_name}"])
        tmp_output.binmode

        begin
          process_image(tmp_output.path, dimensions, format_name)

          url = ImageStorageService.store(
            tmp_output.path,
            store_dir: @store_dir,
            filename: filename
          )

          @model.image_variants.create!(
            image_type: @image_type,
            variant: variant_name,
            format: format_name,
            url: url
          )

          generated[variant_name][format_name] = url
        ensure
          tmp_output.close
          tmp_output.unlink
        end
      end
    end

    generated
  end

  def generate_logo_variants
    generated = {}

    LOGO_VARIANTS.each do |variant_name, max_width|
      generated[variant_name] = {}

      LOGO_FORMATS.each do |format_name|
        filename = "#{variant_name}.#{format_name}"
        tmp_output = Tempfile.new([variant_name, ".#{format_name}"])
        tmp_output.binmode

        begin
          process_logo(tmp_output.path, max_width, format_name)

          url = ImageStorageService.store(
            tmp_output.path,
            store_dir: @store_dir,
            filename: filename
          )

          @model.image_variants.create!(
            image_type: @image_type,
            variant: variant_name,
            format: format_name,
            url: url
          )

          generated[variant_name][format_name] = url
        ensure
          tmp_output.close
          tmp_output.unlink
        end
      end
    end

    generated
  end

  def process_image(output_path, dimensions, format)
    quality = format == "avif" ? 70 : 80

    image = MiniMagick::Image.open(@source_path)

    if dimensions
      image.resize "#{dimensions[0]}x#{dimensions[1]}>"
    end

    image.format(format)
    image.quality(quality.to_s)
    image.write(output_path)
  end

  def process_logo(output_path, max_width, format)
    image = MiniMagick::Image.open(@source_path)

    if max_width && image.width > max_width
      image.resize "#{max_width}x>"
    end

    image.format(format)
    image.write(output_path)
  end
end
