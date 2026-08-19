# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugin::DependencyResolver do
  def build_record(id, version: "1.0.0", dependencies: {}, status: :compatible, reason: nil)
    manifest = instance_double(
      Plugin::Manifest,
      id: id,
      version: version,
      dependencies: dependencies
    )
    instance_double(
      Plugin::Registry::Record,
      id: id,
      version: version,
      manifest: manifest,
      status: status,
      compatible?: %i[compatible enabled].include?(status),
      reason: reason
    )
  end

  describe "#resolve" do
    it "returns all records in order with no dependencies" do
      a = build_record("a")
      b = build_record("b")
      result = described_class.new([a, b]).resolve

      expect(result.ordered.map(&:id)).to contain_exactly("a", "b")
      expect(result.blocked).to be_empty
    end

    it "respects dependency order" do
      a = build_record("a")
      b = build_record("b", dependencies: { "a" => ">=1.0.0" })
      result = described_class.new([a, b]).resolve

      expect(result.ordered.map(&:id)).to eq(%w[a b])
    end

    it "blocks plugins with missing required dependencies" do
      b = build_record("b", dependencies: { "nonexistent" => ">=1.0.0" })
      result = described_class.new([b]).resolve

      expect(result.blocked["b"]).to include("missing required plugin dependency")
    end

    it "blocks plugins with incompatible dependency versions" do
      a = build_record("a", version: "1.0.0")
      b = build_record("b", dependencies: { "a" => ">=2.0.0" })
      result = described_class.new([a, b]).resolve

      expect(result.blocked["b"]).to include("incompatible with 1.0.0")
    end

    it "allows optional dependencies to be missing" do
      # optional_dependencies are declared but not enforced
      a = build_record("a")
      result = described_class.new([a]).resolve

      expect(result.ordered.map(&:id)).to eq(%w[a])
      expect(result.blocked).to be_empty
    end

    it "detects cycles and blocks all involved plugins" do
      a = build_record("a", dependencies: { "b" => ">=1.0.0" })
      b = build_record("b", dependencies: { "a" => ">=1.0.0" })
      result = described_class.new([a, b]).resolve

      expect(result.blocked).to have_key("a")
      expect(result.blocked).to have_key("b")
      expect(result.blocked["a"]).to include("cyclic")
    end

    it "skips @cinelartv/* dependencies (external packages)" do
      a = build_record("a", dependencies: {
        "@cinelartv/core" => "^1.0.0",
        "real-plugin" => ">=1.0.0"
      })
      real = build_record("real-plugin")
      result = described_class.new([a, real]).resolve

      # a depends on real-plugin which exists, so no blocking for that
      expect(result.blocked).to be_empty
      expect(result.ordered.map(&:id)).to eq(%w[real-plugin a])
    end

    it "does not include incompatible records in ordered list" do
      a = build_record("a", status: :blocked, reason: "incompatible")
      b = build_record("b")
      result = described_class.new([a, b]).resolve

      expect(result.ordered.map(&:id)).to eq(%w[b])
    end
  end

  describe ".satisfies?" do
    it "returns true for blank requirement" do
      expect(described_class.satisfies?("1.0.0", "")).to be true
      expect(described_class.satisfies?("1.0.0", nil)).to be true
    end

    it "returns true for wildcard" do
      expect(described_class.satisfies?("1.0.0", "*")).to be true
    end

    it "handles exact version match" do
      expect(described_class.satisfies?("1.0.0", ">=1.0.0")).to be true
      expect(described_class.satisfies?("0.9.0", ">=1.0.0")).to be false
    end

    it "handles npm caret ranges" do
      expect(described_class.satisfies?("1.5.0", "^1.0.0")).to be true
      expect(described_class.satisfies?("2.0.0", "^1.0.0")).to be false
      expect(described_class.satisfies?("1.0.0", "^1.0.0")).to be true
    end

    it "handles npm caret range for 0.x" do
      expect(described_class.satisfies?("0.1.5", "^0.1.0")).to be true
      expect(described_class.satisfies?("0.5.0", "^0.1.0")).to be false
      expect(described_class.satisfies?("0.10.0", "^0.1.0")).to be false
    end

    it "handles complex range expressions" do
      expect(described_class.satisfies?("1.5.0", ">=1.0.0 <2.0.0")).to be true
      expect(described_class.satisfies?("2.0.0", ">=1.0.0 <2.0.0")).to be false
    end

    it "handles || alternatives" do
      expect(described_class.satisfies?("1.0.0", ">=1.0.0 || >=2.0.0")).to be true
      expect(described_class.satisfies?("0.5.0", ">=1.0.0 || >=2.0.0")).to be false
    end
  end
end
