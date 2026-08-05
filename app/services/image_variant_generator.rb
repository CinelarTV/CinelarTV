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

  FORMATS = %w[avif webp].freeze

  def initialize(model:, image_type:, source_path:, store_dir:)
    @model = model
    @image_type = image_type
    @source_path = source_path
    @store_dir = store_dir
  end

  # Generate all variants and persist ImageVariant records.
  # Returns a hash { "original" => { "webp" => "url" }, ... }
  def call
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

  private

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
end
