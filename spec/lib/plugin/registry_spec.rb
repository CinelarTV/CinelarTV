# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugin::Registry do
  let(:tmpdir) { Dir.mktmpdir }
  let(:plugins_dir) { File.join(tmpdir, "plugins") }

  before do
    FileUtils.mkdir_p(plugins_dir)
  end

  after { FileUtils.rm_rf(tmpdir) }

  def create_plugin(name, json_data: {}, plugin_rb: nil)
    dir = File.join(plugins_dir, name)
    FileUtils.mkdir_p(dir)
    unless json_data.empty?
      File.write(File.join(dir, "plugin.json"), json_data.merge("id" => name, "version" => json_data.fetch("version", "1.0.0")).to_json)
    end
    if plugin_rb
      File.write(File.join(dir, "plugin.rb"), plugin_rb)
    else
      File.write(File.join(dir, "plugin.rb"), "# name: #{name}\n# version: 1.0.0\n")
    end
    dir
  end

  describe ".build" do
    it "discovers plugins from subdirectories" do
      create_plugin("plugin-a")
      create_plugin("plugin-b")

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      expect(registry.records.map(&:id)).to contain_exactly("plugin-a", "plugin-b")
    end

    it "skips directories without plugin.rb or plugin.json" do
      FileUtils.mkdir_p(File.join(plugins_dir, "not-a-plugin"))
      create_plugin("real-plugin")

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      expect(registry.records.map(&:id)).to eq(%w[real-plugin])
    end

    it "handles JSON parse errors gracefully" do
      dir = File.join(plugins_dir, "broken")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "plugin.json"), "{invalid json")
      File.write(File.join(dir, "plugin.rb"), "# name: broken\n# version: 1.0.0\n")

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      broken = registry.records.find { |r| r.id == "broken" }
      expect(broken.status).to eq(:blocked)
      expect(broken.reason).to include("invalid plugin manifest")
    end
  end

  describe "#validate!" do
    it "marks invalid manifests as blocked" do
      dir = File.join(plugins_dir, "bad-id")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "plugin.json"), { "id" => "UPPERCASE", "version" => "1.0.0" }.to_json)
      File.write(File.join(dir, "plugin.rb"), "# name: test\n")

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      record = registry.records.find { |r| r.id == "UPPERCASE" }
      expect(record.status).to eq(:blocked)
      expect(record.reason).to include("invalid plugin manifest")
    end

    it "blocks duplicate plugin ids" do
      create_plugin("dup", json_data: { "version" => "1.0.0" })
      dir2 = File.join(plugins_dir, "dup-copy")
      FileUtils.mkdir_p(dir2)
      File.write(File.join(dir2, "plugin.json"), { "id" => "dup", "version" => "2.0.0" }.to_json)
      File.write(File.join(dir2, "plugin.rb"), "# name: dup\n")

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      dup_records = registry.records.select { |r| r.id == "dup" }
      blocked = dup_records.select { |r| r.status == :blocked }
      expect(blocked.length).to eq(1)
      expect(blocked.first.reason).to include("duplicate plugin id")
    end

    it "blocks plugins with incompatible core version" do
      create_plugin("old-plugin", json_data: {
        "version" => "1.0.0",
        "core" => { "version" => ">=2.0.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      record = registry.records.find { |r| r.id == "old-plugin" }
      expect(record.status).to eq(:blocked)
      expect(record.reason).to include("incompatible core")
    end

    it "marks compatible plugins" do
      create_plugin("good-plugin", json_data: {
        "version" => "1.0.0",
        "core" => { "version" => ">=0.1.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      record = registry.records.find { |r| r.id == "good-plugin" }
      expect(record.status).to eq(:compatible)
    end

    it "blocks plugins with missing dependencies" do
      create_plugin("a")
      create_plugin("b", json_data: {
        "version" => "1.0.0",
        "dependencies" => { "nonexistent" => ">=1.0.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      record = registry.records.find { |r| r.id == "b" }
      expect(record.status).to eq(:blocked)
      expect(record.reason).to include("missing required plugin dependency")
    end

    it "detects cyclic dependencies" do
      create_plugin("alpha", json_data: {
        "version" => "1.0.0",
        "dependencies" => { "beta" => ">=1.0.0" }
      })
      create_plugin("beta", json_data: {
        "version" => "1.0.0",
        "dependencies" => { "alpha" => ">=1.0.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      alpha = registry.records.find { |r| r.id == "alpha" }
      beta = registry.records.find { |r| r.id == "beta" }
      expect(alpha.status).to eq(:blocked)
      expect(beta.status).to eq(:blocked)
    end

    it "respects topological order" do
      create_plugin("base")
      create_plugin("mid", json_data: {
        "version" => "1.0.0",
        "dependencies" => { "base" => ">=1.0.0" }
      })
      create_plugin("top", json_data: {
        "version" => "1.0.0",
        "dependencies" => { "mid" => ">=1.0.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      ids = registry.ordered.map(&:id)
      expect(ids.index("base")).to be < ids.index("mid")
      expect(ids.index("mid")).to be < ids.index("top")
    end
  end

  describe "#frontend_records" do
    it "returns enabled records with frontend entry" do
      create_plugin("frontend-plugin", json_data: {
        "version" => "1.0.0",
        "frontend" => { "entry" => "app/index.ts" },
        "core" => { "version" => ">=0.1.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      registry.activate!
      records = registry.frontend_records
      expect(records.length).to eq(1)
      expect(records.first[:id]).to eq("frontend-plugin")
      expect(records.first[:entry]).to eq("app/index.ts")
    end

    it "excludes plugins without frontend entry" do
      create_plugin("backend-only", json_data: {
        "version" => "1.0.0",
        "core" => { "version" => ">=0.1.0" }
      })

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      registry.activate!
      records = registry.frontend_records
      expect(records).to be_empty
    end
  end

  describe "legacy plugin (plugin.rb without plugin.json)" do
    it "still loads and activates" do
      dir = File.join(plugins_dir, "legacy")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "plugin.rb"), <<~RUBY)
        # name: legacy-plugin
        # version: 1.0.0
      RUBY

      registry = described_class.build(root: plugins_dir, core_version: "1.0.0")
      record = registry.records.find { |r| r.id == "legacy-plugin" }
      expect(record).not_to be_nil
      expect(record.status).to eq(:compatible)
    end
  end
end
