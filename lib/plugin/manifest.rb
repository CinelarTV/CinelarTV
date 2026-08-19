# frozen_string_literal: true

require "json"

module Plugin
  class Manifest
    attr_reader :path, :data, :legacy_metadata, :parse_error

    def self.from_directory(directory)
      json_path = File.join(directory, "plugin.json")
      ruby_path = File.join(directory, "plugin.rb")
      data = File.exist?(json_path) ? JSON.parse(File.read(json_path)) : {}
      metadata = File.exist?(ruby_path) ? Plugin::Metadata.parse(File.read(ruby_path)) : nil
      new(directory, data, metadata)
    end

    def initialize(path, data, legacy_metadata = nil)
      @path = path
      @data = data || {}
      @legacy_metadata = legacy_metadata
      @parse_error = data["parse_error"]
    end

    def id = data["id"].presence || data["name"].presence || legacy_metadata&.name
    def version = data["version"].presence || legacy_metadata&.version || "0.0.0"
    def frontend = data["frontend"] || {}
    def backend = data["backend"] || {}
    def dependencies = data["dependencies"] || {}
    def optional_dependencies = data["optionalDependencies"] || {}
    def frontend_entry = frontend["entry"].presence || data["entry"].presence
    def backend_entry = backend["entry"].presence || (File.exist?(File.join(path, "plugin.rb")) ? "plugin.rb" : nil)
    def core_requirement
      return data.dig("core", "version").presence if data.dig("core", "version").present?
      return data["cinelartv_version"].presence if data["cinelartv_version"].present?

      legacy_metadata&.required_version&.then { |version| ">=#{version}" }
    end
    def frontend_api_requirement = data.dig("core", "frontendApi").presence

    def valid?
      return false if @parse_error
      id.present? && id.match?(/\A[a-z0-9][a-z0-9\-]*\z/) && version.present?
    end

    def plugin_rb_path
      backend_entry && File.join(path, backend_entry)
    end
  end
end
