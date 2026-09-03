# frozen_string_literal: true

module SvgSprite
  # All icons that are always included in the sprite.
  # Names use the project convention (camelCase or kebab-case as used in templates).
  SVG_ICONS = Set.new(%w[
    activity award airplay arrowRightLeft arrowRight arrowLeft box check
    copy checkCircle chevronDown chevronLeft chevronRight
    chevronUp clapperboard creditCard gripVertical helpCircle info
    calendar clock lock
    loader logOut pause maximize minimize play frown fastForward
    playCircle playSquare plus rotateCcw rotateCw search settings
    shieldQuestion sparkles thumbsUp thumbsDown user wrench x hardDrive
    circleDollarSign brush testTube2 telescope code2 cpu star satelliteDish
    rocket trash2 pencil layoutGrid bookmark volume1 volume2
    volumeX home packageOpen webhook cast shrink messageCircleMore
    messageCircleOff mail shield-check shuffle languages
    eye save send bold italic strikethrough
    heading-1 heading-2 heading-3
    list list-ordered quote code minus link
    undo redo braces monitor smartphone
    mail-check key-round unlock users closed-caption
    chart-pie toy-brick
  ]).freeze

  # Player icons need duplicate vjs-icon-* symbols for Video.js compatibility.
  PLAYER_ICONS = Set.new(%w[play pause maximize minimize volume2 volumeX]).freeze

  CACHE_KEY_PREFIX = "svg_sprite/v2"

  # ─── Public API ──────────────────────────────────────────────────────────────

  def self.all_icons
    icons = Set.new(SVG_ICONS)
    icons.merge(settings_icons)
    icons.merge(additional_icons)
    icons.merge(plugin_icons)
    icons.merge(custom_icons)
    icons.delete_if { |i| i.blank? || i.include?("/") }
    icons.map!(&:strip)
    icons.to_a.sort
  end

  def self.cached_bundle
    Rails.cache.fetch("#{CACHE_KEY_PREFIX}/#{sources_fingerprint}", expires_in: 24.hours) do
      uncached_bundle
    end
  end

  def self.uncached_bundle
    icons = all_icons
    svg = +"<svg xmlns='http://www.w3.org/2000/svg' style='display: none'>"
    icons.each do |icon_name|
      symbol = icon_symbol(icon_name)
      svg << symbol if symbol
    end
    svg << "</svg>"
    minify_svg(svg)
  end

  def self.version
    Digest::SHA1.hexdigest(cached_bundle)
  end

  def self.path
    "/svg-sprite.svg?v=#{version}"
  end

  def self.icon_picker_search(filter = "")
    icons = all_icons
    icons.select! { |id| id.include?(filter) } if filter.present?
    icons.first(500).map { |id| { id: id } }
  end

  def self.expire_cache
    Rails.cache.delete_matched("#{CACHE_KEY_PREFIX}/*")
  end

  def self.preload
    # Preload the sprite into Rails.cache to avoid a cache miss on first request.
    cached_bundle
  end

  # ─── Source resolution ───────────────────────────────────────────────────────

  def self.icon_symbol(icon_name)
    source = resolve_source(icon_name)

    case source
    when :lucide
      lucide_symbol(icon_name)
    when :plugin_svg
      plugin_svg_symbol(icon_name)
    else
      nil
    end
  end

  def self.resolve_source(name)
    # Check if it's a custom icon from a plugin SVG file
    custom_icons.each do |custom_name|
      return :plugin_svg if custom_name == name
    end

    # Otherwise try Lucide
    filename = to_lucide_filename(name)
    path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
    return :lucide if File.exist?(path)

    nil
  end

  # ─── Lucide icons ────────────────────────────────────────────────────────────

  # Lucide presentation attributes (inherited by child elements inside <symbol>).
  LUCIDE_ATTRS = ' fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'

  def self.lucide_symbol(icon_name)
    filename = to_lucide_filename(icon_name)
    path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
    return nil unless File.exist?(path)

    svg_content = File.read(path)
    inner = svg_content[/<svg[^>]*>(.*)<\/svg>/m, 1]
    return nil unless inner

    id = to_kebab_case(icon_name)
    symbol = +%(<symbol id="#{id}" viewBox="0 0 24 24"#{LUCIDE_ATTRS}>#{inner}</symbol>)

    if PLAYER_ICONS.include?(icon_name)
      symbol << %(<symbol id="vjs-icon-#{id}" viewBox="0 0 24 24"#{LUCIDE_ATTRS}>#{inner}</symbol>)
    end

    symbol
  end

  # ─── Custom plugin SVG icons ─────────────────────────────────────────────────

  def self.plugin_svg_symbol(icon_name)
    plugin_svg_files.each do |path, symbols|
      if symbols.key?(icon_name)
        id = to_kebab_case(icon_name)
        return "<symbol id=\"#{id}\" viewBox=\"0 0 24 24\">#{symbols[icon_name]}</symbol>"
      end
    end
    nil
  end

  def self.plugin_svg_files
    @plugin_svg_files ||= begin
      result = {}
      Dir.glob(Rails.root.join("plugins", "*", "svg-icons", "*.svg")).each do |path|
        content = File.read(path)
        symbols = {}
        content.scan(/<symbol\s+id="([^"]+)"[^>]*>(.*?)<\/symbol>/m) do |id, body|
          symbols[id] = body
        end
        result[path] = symbols
      end
      result
    end
  end

  # ─── Icon sources ────────────────────────────────────────────────────────────

  def self.settings_icons
    icons = []
    SiteSetting.defined_fields.each do |field|
      key = field[:key].to_s
      next unless key.end_with?("_icon")

      value = SiteSetting.get(field[:key])
      next unless value.is_a?(String) && value.present?

      icons |= value.split("|").map(&:strip).reject(&:blank?)
    end
    icons
  end

  def self.additional_icons
    value = SiteSetting.additional_icons
    return [] unless value.is_a?(String) && value.present?
    value.split("|").map(&:strip).reject(&:blank?)
  end

  def self.plugin_icons
    PluginRegistry.svg_icons || []
  end

  def self.custom_icons
    icons = []
    Dir.glob(Rails.root.join("plugins", "*", "svg-icons", "*.svg")).each do |path|
      content = File.read(path)
      content.scan(/id="([^"]+)"/).each { |match| icons << match[0] }
    end
    icons.uniq
  end

  # ─── Fingerprinting ─────────────────────────────────────────────────────────

  def self.sources_fingerprint
    parts = []
    parts << SVG_ICONS.sort.join(",")
    parts << settings_icons.sort.join(",")
    parts << additional_icons.sort.join(",")
    parts << plugin_icons.sort.join(",")
    parts << custom_icons.sort.join(",")
    parts << plugin_svg_mtime
    Digest::SHA1.hexdigest(parts.join("|"))
  end

  def self.plugin_svg_mtime
    files = Dir.glob(Rails.root.join("plugins", "*", "svg-icons", "*.svg")).sort
    mtimes = files.map { |f| File.mtime(f).to_i }
    mtimes.join(",")
  end

  # ─── Naming helpers ──────────────────────────────────────────────────────────

  def self.minify_svg(svg)
    svg.split("\n").filter_map { |line| line.strip.presence }.join
  end

  def self.to_kebab_case(str)
    str
      .gsub(/([a-z])([A-Z])/, '\1-\2')
      .gsub(/([a-zA-Z])(\d)/, '\1-\2')
      .downcase
  end

  def self.to_pascal_case(str)
    str
      .gsub(/(^|_|-|\s)([a-z])/) { |m| m.upcase }
      .gsub(/[-_\s]/, "")
  end

  def self.to_lucide_filename(name)
    pascal = to_pascal_case(name)
    kebab = pascal
      .gsub(/([a-z])([A-Z])/, '\1-\2')
      .gsub(/([a-zA-Z])(\d)/, '\1-\2')
      .gsub(/(\d)([a-zA-Z])/, '\1-\2')
      .downcase
    "#{kebab}.svg"
  end
end
