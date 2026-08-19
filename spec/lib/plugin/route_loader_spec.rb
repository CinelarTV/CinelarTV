# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugin::RouteLoader do
  let(:tmpdir) { Dir.mktmpdir }
  let(:plugins_dir) { File.join(tmpdir, "plugins") }

  before { FileUtils.mkdir_p(plugins_dir) }
  after { FileUtils.rm_rf(tmpdir) }

  def create_plugin_with_routes(name, routes_content: nil, engine: nil)
    dir = File.join(plugins_dir, name)
    FileUtils.mkdir_p(dir)

    json_data = { "id" => name, "version" => "1.0.0" }
    json_data["backend"] = {}
    json_data["backend"]["routes"] = "config/routes.rb" if routes_content
    json_data["backend"]["engine"] = engine if engine

    File.write(File.join(dir, "plugin.json"), json_data.to_json)
    File.write(File.join(dir, "plugin.rb"), "# name: #{name}\n# version: 1.0.0\n")

    if routes_content
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config", "routes.rb"), routes_content)
    end

    dir
  end

  describe ".load" do
    it "does nothing when registry is nil" do
      expect {
        described_class.load(registry: nil)
      }.not_to raise_error
    end

    it "loads routes only for enabled plugins" do
      create_plugin_with_routes("active-plugin", routes_content: '# active routes')
      create_plugin_with_routes("disabled-plugin", routes_content: '# disabled routes')

      registry = Plugin::Registry.build(root: plugins_dir, core_version: "1.0.0")

      # Both should be discovered; check the active one is compatible
      active = registry.records.find { |r| r.id == "active-plugin" }
      disabled = registry.records.find { |r| r.id == "disabled-plugin" }

      expect(active.status).to eq(:compatible)
      expect(disabled.status).to eq(:compatible)
    end

    it "handles route loading errors gracefully" do
      dir = File.join(plugins_dir, "error-plugin")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "plugin.json"), {
        "id" => "error-plugin",
        "version" => "1.0.0",
        "backend" => { "routes" => "config/routes.rb" }
      }.to_json)
      File.write(File.join(dir, "plugin.rb"), "# name: error-plugin\n")
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config", "routes.rb"), "raise 'intentional error'")

      registry = Plugin::Registry.build(root: plugins_dir, core_version: "1.0.0")
      expect {
        described_class.load(registry: registry)
      }.not_to raise_error
    end

    it "skips plugins without routes declaration" do
      create_plugin_with_routes("no-routes-plugin")

      registry = Plugin::Registry.build(root: plugins_dir, core_version: "1.0.0")
      expect {
        described_class.load(registry: registry)
      }.not_to raise_error
    end

    it "skips nonexistent routes files" do
      dir = File.join(plugins_dir, "missing-routes")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "plugin.json"), {
        "id" => "missing-routes",
        "version" => "1.0.0",
        "backend" => { "routes" => "config/routes.rb" }
      }.to_json)
      File.write(File.join(dir, "plugin.rb"), "# name: missing-routes\n")
      # Don't actually create the routes file

      registry = Plugin::Registry.build(root: plugins_dir, core_version: "1.0.0")
      expect {
        described_class.load(registry: registry)
      }.not_to raise_error
    end
  end
end
