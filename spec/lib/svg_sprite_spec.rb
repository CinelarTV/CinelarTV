# frozen_string_literal: true

require "rails_helper"

RSpec.describe SvgSprite do
  before do
    Rails.cache.clear
    SvgSprite.instance_variable_set(:@plugin_svg_files, nil)
    PluginRegistry.clear_all
    PluginRegistry.reset!
    allow(SiteSetting).to receive(:additional_icons).and_return("")
  end

  describe ".to_kebab_case" do
    it "converts camelCase to kebab-case" do
      expect(described_class.to_kebab_case("volume2")).to eq("volume-2")
      expect(described_class.to_kebab_case("trash2")).to eq("trash-2")
      expect(described_class.to_kebab_case("code2")).to eq("code-2")
      expect(described_class.to_kebab_case("volumeX")).to eq("volume-x")
      expect(described_class.to_kebab_case("arrowRight")).to eq("arrow-right")
    end

    it "preserves existing kebab-case" do
      expect(described_class.to_kebab_case("shield-check")).to eq("shield-check")
      expect(described_class.to_kebab_case("heading-1")).to eq("heading-1")
    end

    it "handles single words" do
      expect(described_class.to_kebab_case("play")).to eq("play")
      expect(described_class.to_kebab_case("settings")).to eq("settings")
    end
  end

  describe ".to_pascal_case" do
    it "converts kebab-case to PascalCase" do
      expect(described_class.to_pascal_case("shield-check")).to eq("ShieldCheck")
      expect(described_class.to_pascal_case("heading-1")).to eq("Heading1")
      expect(described_class.to_pascal_case("volume-2")).to eq("Volume2")
    end

    it "converts camelCase to PascalCase" do
      expect(described_class.to_pascal_case("arrowRight")).to eq("ArrowRight")
      expect(described_class.to_pascal_case("volumeX")).to eq("VolumeX")
    end

    it "capitalizes single words" do
      expect(described_class.to_pascal_case("play")).to eq("Play")
      expect(described_class.to_pascal_case("settings")).to eq("Settings")
    end
  end

  describe ".to_lucide_filename" do
    {
      "play" => "play.svg",
      "settings" => "settings.svg",
      "volume2" => "volume-2.svg",
      "volume1" => "volume-1.svg",
      "volumeX" => "volume-x.svg",
      "trash2" => "trash-2.svg",
      "code2" => "code-2.svg",
      "testTube2" => "test-tube-2.svg",
      "heading-1" => "heading-1.svg",
      "heading-2" => "heading-2.svg",
      "heading-3" => "heading-3.svg",
      "shield-check" => "shield-check.svg",
      "arrowRight" => "arrow-right.svg",
      "arrowRightLeft" => "arrow-right-left.svg",
      "checkCircle" => "check-circle.svg",
      "circleDollarSign" => "circle-dollar-sign.svg",
      "logOut" => "log-out.svg",
      "key-round" => "key-round.svg",
      "mail-check" => "mail-check.svg",
      "list-ordered" => "list-ordered.svg",
      "playCircle" => "play-circle.svg",
      "playSquare" => "play-square.svg",
      "smartphone" => "smartphone.svg",
      "braces" => "braces.svg",
      "maximize" => "maximize.svg",
      "minimize" => "minimize.svg"
    }.each do |name, expected_filename|
      it "converts '#{name}' to '#{expected_filename}'" do
        expect(described_class.to_lucide_filename(name)).to eq(expected_filename)
      end
    end
  end

  describe ".all_icons" do
    it "includes all SVG_ICONS" do
      icons = described_class.all_icons
      described_class::SVG_ICONS.each do |icon|
        expect(icons).to include(icon), "Expected all_icons to include '#{icon}'"
      end
    end

    it "returns a sorted array" do
      expect(described_class.all_icons).to eq(described_class.all_icons.sort)
    end

    it "includes settings_icons from additional_icons" do
      allow(SiteSetting).to receive(:additional_icons).and_return("foo|bar")
      allow(SiteSetting).to receive(:defined_fields).and_return(
        [{ key: :additional_icons, options: { type: "string" } }]
      )
      allow(SiteSetting).to receive(:get).with(:additional_icons).and_return("foo|bar")

      icons = described_class.all_icons
      expect(icons).to include("foo")
      expect(icons).to include("bar")
    end
  end

  describe ".settings_icons" do
    it "reads pipe-delimited values from settings ending with _icon" do
      allow(SiteSetting).to receive(:defined_fields).and_return([
        { key: :site_name, options: { type: "string" } },
        { key: :custom_logo_icon, options: { type: "string" } }
      ])
      allow(SiteSetting).to receive(:get).with(:site_name).and_return("My Site")
      allow(SiteSetting).to receive(:get).with(:custom_logo_icon).and_return("star|heart")

      icons = described_class.settings_icons
      expect(icons).to contain_exactly("star", "heart")
    end

    it "ignores settings that don't end with _icon" do
      allow(SiteSetting).to receive(:defined_fields).and_return([
        { key: :site_name, options: { type: "string" } },
        { key: :enable_splash_screen, options: { type: "boolean" } }
      ])

      expect(described_class.settings_icons).to eq([])
    end

    it "ignores empty or blank values" do
      allow(SiteSetting).to receive(:defined_fields).and_return([
        { key: :additional_icons, options: { type: "string" } }
      ])
      allow(SiteSetting).to receive(:get).with(:additional_icons).and_return("")

      expect(described_class.settings_icons).to eq([])
    end
  end

  describe ".plugin_icons" do
    it "returns icons from PluginRegistry.svg_icons" do
      plugin = double("Plugin", enabled?: true)
      PluginRegistry.register_svg_icon("my-plugin-icon", plugin)

      expect(described_class.plugin_icons).to include("my-plugin-icon")
    ensure
      PluginRegistry.clear_all
      PluginRegistry.reset!
    end
  end

  describe ".resolve_source" do
    it "returns :lucide for icons that exist in lucide-static" do
      path = Rails.root.join("node_modules", "lucide-static", "icons", "play.svg")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(path).and_return(true)
      expect(described_class.resolve_source("play")).to eq(:lucide)
    end

    it "returns nil for icons that don't exist anywhere" do
      expect(described_class.resolve_source("nonexistent-icon-xyz")).to be_nil
    end
  end

  describe ".icon_symbol" do
    before do
      allow(File).to receive(:exist?).and_call_original
      %w[play settings].each do |name|
        filename = described_class.to_lucide_filename(name)
        path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
        allow(File).to receive(:exist?).with(path).and_return(true)
      end
      allow(File).to receive(:read).and_call_original
      %w[play settings].each do |name|
        filename = described_class.to_lucide_filename(name)
        path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
        allow(File).to receive(:read).with(path).and_return("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><path d=\"M5 3l14 9-14 9V3z\"/></svg>")
      end
    end

    it "generates a <symbol> element for Lucide icons" do
      symbol = described_class.icon_symbol("play")
      expect(symbol).to include("<symbol id=\"play\"")
      expect(symbol).to include("viewBox=\"0 0 24 24\"")
      expect(symbol).to include("</symbol>")
    end

    it "includes vjs-icon-* alias for player icons" do
      symbol = described_class.icon_symbol("play")
      expect(symbol).to include("<symbol id=\"vjs-icon-play\"")
    end

    it "does not include vjs-icon-* for non-player icons" do
      symbol = described_class.icon_symbol("settings")
      expect(symbol).not_to include("vjs-icon-settings")
    end

    it "returns nil for nonexistent icons" do
      expect(described_class.icon_symbol("nonexistent-icon-xyz")).to be_nil
    end
  end

  describe ".uncached_bundle" do
    it "generates a valid SVG with symbol elements" do
      allow(File).to receive(:exist?).and_call_original
      %w[play settings].each do |name|
        filename = described_class.to_lucide_filename(name)
        path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
        allow(File).to receive(:exist?).with(path).and_return(true)
      end
      allow(File).to receive(:read).and_call_original
      %w[play settings].each do |name|
        filename = described_class.to_lucide_filename(name)
        path = Rails.root.join("node_modules", "lucide-static", "icons", filename)
        allow(File).to receive(:read).with(path).and_return("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><path d=\"M5 3l14 9-14 9V3z\"/></svg>")
      end

      bundle = described_class.uncached_bundle
      expect(bundle).to start_with("<svg xmlns='http://www.w3.org/2000/svg'")
      expect(bundle).to end_with("</svg>")
      expect(bundle).to include("<symbol id=\"play\"")
      expect(bundle).to include("<symbol id=\"settings\"")
    end
  end

  describe ".cached_bundle" do
    it "returns the same result on consecutive calls" do
      first = described_class.cached_bundle
      second = described_class.cached_bundle
      expect(first).to eq(second)
    end
  end

  describe ".version" do
    it "returns a SHA1 hex digest" do
      version = described_class.version
      expect(version).to match(/\A[a-f0-9]{40}\z/)
    end

    it "changes when icons change" do
      v1 = described_class.version
      allow(SiteSetting).to receive(:defined_fields).and_return([
        { key: :dynamic_icon_field, options: { type: "string" } }
      ])
      allow(SiteSetting).to receive(:get).with(:dynamic_icon_field).and_return("dynamic-icon")
      allow(SiteSetting).to receive(:additional_icons).and_return("extra-icon")
      Rails.cache.clear
      v2 = described_class.version
      expect(v1).not_to eq(v2)
    end
  end

  describe ".path" do
    it "returns a versioned URL" do
      path = described_class.path
      expect(path).to start_with("/svg-sprite.svg?v=")
    end
  end

  describe ".icon_picker_search" do
    it "returns all icons when no filter" do
      results = described_class.icon_picker_search
      expect(results.length).to be > 0
      expect(results.first).to have_key(:id)
    end

    it "filters by keyword" do
      results = described_class.icon_picker_search("play")
      ids = results.map { |r| r[:id] }
      expect(ids).to all(include("play"))
    end

    it "returns empty array when no match" do
      results = described_class.icon_picker_search("zzz-nonexistent-zzz")
      expect(results).to eq([])
    end
  end

  describe ".expire_cache" do
    it "clears the sprite cache" do
      bundle1 = described_class.cached_bundle
      bundle2 = described_class.cached_bundle
      expect(bundle1).to eq(bundle2)

      described_class.expire_cache
      expect { described_class.expire_cache }.not_to raise_error
    end
  end
end
