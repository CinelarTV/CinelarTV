# frozen_string_literal: true

module ColorHelper
  def generate_color_variants(base_color, name)
    [50, 100, 200, 300, 400, 500, 600, 700, 800, 900].map do |variant|
      generate_variant_color(base_color, variant, name)
    end.join("\n").html_safe
  end

  def generate_variant_color(base_color, variant, name)
    rgb = base_color.delete("#").scan(/../).map(&:hex)
    hex = rgb.map { |c| adjust_color_channel(c, variant).to_s(16).rjust(2, "0") }.join

    "--c-#{name}-#{variant}: ##{hex};"
  end

  private

  def adjust_color_channel(channel, variant)
    direction = channel < 128 ? 1 : -1
    [[0, (channel + direction * variant * 0.1).round, 255].sort[1], 255].min
  end
end