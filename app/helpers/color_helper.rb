# frozen_string_literal: true

module ColorHelper
  def generate_color_variants(base_color, name)
    variants = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]

    css_variables = variants.map do |variant|
      generate_variant_color(base_color, variant, name)
    end

    css_variables.join("\n").html_safe
  end

  def generate_color_rgb(base_color, name)
    rgb = hex_to_rgb(base_color)
    "--c-#{name}-rgb: #{rgb};"
  end

  def generate_color_variants_with_rgb(base_color, name)
    result = generate_color_variants(base_color, name)
    result += "\n        " + generate_color_rgb(base_color, name)
    result.html_safe
  end

  private

  def generate_variant_color(base_color, variant, name)
    lightness_adjustment = (500 - variant) / 500.0 * 0.9
    adjusted_color = ColorMath.scale_color_lightness(base_color, lightness_adjustment)
    "--c-#{name}-#{variant}: ##{adjusted_color};"
  end

  def hex_to_rgb(hex)
    hex = hex.to_s.gsub('#', '').gsub(/[^0-9a-fA-F]/, '')[0, 6]
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    "#{r}, #{g}, #{b}"
  end
end