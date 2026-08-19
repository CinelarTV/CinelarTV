# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugin::SerializerExtensionRegistry do
  before { described_class.clear! }

  after { described_class.clear! }

  describe ".register" do
    it "registers an extension" do
      ext = described_class.register(
        ContentSerializer,
        :custom_field,
        plugin_name: "test-plugin"
      ) { |obj| "value_for_#{obj.id}" }

      expect(ext).to be_a(Plugin::SerializerExtension)
      expect(described_class.extensions_for(ContentSerializer)).to include(ext)
    end

    it "returns the extension object" do
      ext = described_class.register(
        ContentSerializer,
        :test_attr,
        plugin_name: "p"
      ) { "hello" }

      expect(ext.attribute_name).to eq(:test_attr)
      expect(ext.plugin_name).to eq("p")
    end
  end

  describe ".extensions_for" do
    it "returns extensions for a specific serializer class" do
      described_class.register(ContentSerializer, :field_a, plugin_name: "p1") { "a" }
      described_class.register(CurrentUserSerializer, :field_b, plugin_name: "p2") { "b" }

      content_exts = described_class.extensions_for(ContentSerializer)
      expect(content_exts.length).to eq(1)
      expect(content_exts.first.attribute_name).to eq(:field_a)
    end

    it "returns empty array when no extensions exist" do
      expect(described_class.extensions_for(ContentSerializer)).to eq([])
    end
  end

  describe ".remove_by_plugin" do
    it "removes all extensions for a given plugin" do
      described_class.register(ContentSerializer, :f1, plugin_name: "plugin-a") { "a" }
      described_class.register(ContentSerializer, :f2, plugin_name: "plugin-b") { "b" }
      described_class.register(ContentSerializer, :f3, plugin_name: "plugin-a") { "a2" }

      described_class.remove_by_plugin("plugin-a")

      exts = described_class.extensions_for(ContentSerializer)
      expect(exts.length).to eq(1)
      expect(exts.first.attribute_name).to eq(:f2)
    end
  end

  describe ".clear!" do
    it "removes all extensions" do
      described_class.register(ContentSerializer, :f1, plugin_name: "p") { "v" }
      described_class.clear!

      expect(described_class.extensions_for(ContentSerializer)).to be_empty
    end
  end
end

RSpec.describe Plugin::SerializerExtension do
  describe "#enabled?" do
    it "returns true when no condition is set" do
      ext = described_class.new(ContentSerializer, :test, plugin_name: "p") { "v" }
      expect(ext.enabled?(double("obj"), nil, {})).to be true
    end

    it "evaluates the condition block" do
      ext = described_class.new(
        ContentSerializer, :test, plugin_name: "p",
        condition: ->(obj, _scope, _opts) { obj.respond_to?(:id) }
      ) { "v" }

      expect(ext.enabled?(double("obj", id: 1), nil, {})).to be true
      expect(ext.enabled?(Object.new, nil, {})).to be false
    end
  end
end

RSpec.describe ActiveModel::Serializer do
  before { Plugin::SerializerExtensionRegistry.clear! }
  after { Plugin::SerializerExtensionRegistry.clear! }

  # Minimal test serializer
  let(:test_serializer_class) do
    Class.new(ActiveModel::Serializer) do
      attributes :id, :name

      def id
        object[:id]
      end

      def name
        object[:name]
      end
    end
  end

  it "includes plugin extension attributes in serialization output" do
    Plugin::SerializerExtensionRegistry.register(
      test_serializer_class,
      :extra_field,
      plugin_name: "test"
    ) { |_obj, _scope, _opts| "extra_value" }

    serializer = test_serializer_class.new({ id: 1, name: "Test" })
    result = serializer.as_json

    expect(result[:extra_field]).to eq("extra_value")
    expect(result[:id]).to eq(1)
    expect(result[:name]).to eq("Test")
  end

  it "conditionally includes extension attributes" do
    Plugin::SerializerExtensionRegistry.register(
      test_serializer_class,
      :conditional_field,
      plugin_name: "test",
      condition: ->(obj, _scope, _opts) { obj[:id] == 1 }
    ) { "present" }

    serializer1 = test_serializer_class.new({ id: 1, name: "A" })
    expect(serializer1.as_json[:conditional_field]).to eq("present")

    serializer2 = test_serializer_class.new({ id: 2, name: "B" })
    expect(serializer2.as_json).not_to have_key(:conditional_field)
  end

  it "does not affect serializers without extensions" do
    serializer = test_serializer_class.new({ id: 1, name: "Test" })
    result = serializer.as_json

    expect(result.keys.sort).to eq(%i[id name])
  end
end
