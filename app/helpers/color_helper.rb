# frozen_string_literal: true

module ColorHelper
  def generate_color_variants(base_color, name)
    variants = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]

    css_variables = variants.map do |variant|
      generate_variant_color(base_color, variant, name)
    end

    css_variables.join("\n").html_safe
  end

  def generate_variant_color(base_color, variant, name)
    # Calcular el ajuste de luminosidad basado en la variante
    # 500 es el color base (0% de ajuste)
    # 50 = más claro (+90%), 900 = más oscuro (-90%)
    lightness_adjustment = (500 - variant) / 500.0 * 0.9
    
    adjusted_color = ColorMath.scale_color_lightness(base_color, lightness_adjustment)
    
    "--c-#{name}-#{variant}: ##{adjusted_color};"
  end
end