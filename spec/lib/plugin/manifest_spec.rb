# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugin::Manifest do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  describe ".from_directory" do
    it "parses plugin.json when present" do
      File.write(File.join(tmpdir, "plugin.json"), {
        "id" => "test-plugin",
        "version" => "1.2.3",
        "frontend" => { "entry" => "app/index.ts" },
        "backend" => { "entry" => "plugin.rb" }
      }.to_json)

      manifest = described_class.from_directory(tmpdir)
      expect(manifest.id).to eq("test-plugin")
      expect(manifest.version).to eq("1.2.3")
      expect(manifest.frontend_entry).to eq("app/index.ts")
      expect(manifest.backend_entry).to eq("plugin.rb")
    end

    it "falls back to legacy metadata when no plugin.json" do
      File.write(File.join(tmpdir, "plugin.rb"), <<~RUBY)
        # name: legacy-plugin
        # version: 0.5.0
      RUBY

      manifest = described_class.from_directory(tmpdir)
      expect(manifest.id).to eq("legacy-plugin")
      expect(manifest.version).to eq("0.5.0")
    end

    it "prefers plugin.json id over legacy metadata" do
      File.write(File.join(tmpdir, "plugin.json"), {
        "id" => "json-plugin",
        "version" => "2.0.0"
      }.to_json)
      File.write(File.join(tmpdir, "plugin.rb"), <<~RUBY)
        # name: legacy-name
        # version: 0.1.0
      RUBY

      manifest = described_class.from_directory(tmpdir)
      expect(manifest.id).to eq("json-plugin")
      expect(manifest.version).to eq("2.0.0")
    end

    it "handles missing files gracefully" do
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.id).to be_nil
      expect(manifest.version).to eq("0.0.0")
      expect(manifest).not_to be_valid
    end
  end

  describe "#valid?" do
    it "returns true for valid id and version" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "my-plugin", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest).to be_valid
    end

    it "rejects uppercase ids" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "My-Plugin", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest).not_to be_valid
    end

    it "rejects ids starting with hyphen" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "-bad", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest).not_to be_valid
    end

    it "allows hyphens in the middle" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "my-cool-plugin", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest).to be_valid
    end
  end

  describe "#core_requirement" do
    it "reads from core.version" do
      File.write(File.join(tmpdir, "plugin.json"), {
        "id" => "p", "version" => "1.0.0",
        "core" => { "version" => ">=1.0.0 <2.0.0" }
      }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.core_requirement).to eq(">=1.0.0 <2.0.0")
    end

    it "falls back to cinelartv_version" do
      File.write(File.join(tmpdir, "plugin.json"), {
        "id" => "p", "version" => "1.0.0",
        "cinelartv_version" => ">=0.5.0"
      }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.core_requirement).to eq(">=0.5.0")
    end

    it "returns nil when no requirement declared" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "p", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.core_requirement).to be_nil
    end
  end

  describe "#dependencies" do
    it "returns empty hash when none declared" do
      File.write(File.join(tmpdir, "plugin.json"), { "id" => "p", "version" => "1.0.0" }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.dependencies).to eq({})
    end

    it "returns declared dependencies" do
      File.write(File.join(tmpdir, "plugin.json"), {
        "id" => "p", "version" => "1.0.0",
        "dependencies" => { "other-plugin" => "^1.0.0" }
      }.to_json)
      manifest = described_class.from_directory(tmpdir)
      expect(manifest.dependencies).to eq("other-plugin" => "^1.0.0")
    end
  end
end
