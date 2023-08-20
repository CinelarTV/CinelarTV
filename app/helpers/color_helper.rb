module ColorHelper
  def generate_color_variants(base_color, name)
    variants = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]

    css_variables = variants.map do |variant|
      generate_variant_color(base_color, variant, name)
    end

    css_variables.join("\n").html_safe
  end

  def generate_variant_color(base_color, variant, name)
    base_color_hex = base_color.delete("#")
    base_color_rgb = [base_color_hex[0..1], base_color_hex[2..3], base_color_hex[4..5]].map(&:hex)
    adjusted_rgb = base_color_rgb.map { |c| adjust_color_channel(c, variant) }

    "--c-#{name}-#{variant}: #" + adjusted_rgb.map { |c| c.to_s(16).rjust(2, "0") }.join("") + ";"
  end

  private

  def adjust_color_channel(channel_value, variant)
    # Convert channel_value to a number
    channel_value = channel_value.to_i
    # Adjust the color channel
    adjusted_value = channel_value - variant * 0.1 * (channel_value < 128 ? -1 : 1) # Inverted adjustment for darker variants
    # Round the result
    adjusted_value = adjusted_value.round
    puts "adjusted_value: #{adjusted_value}"
    # Clamp the result to the valid range
    [0, adjusted_value, 255].sort[1]
    end
end
