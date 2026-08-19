# frozen_string_literal: true

module Plugin
  class Registry
    Record = Struct.new(:manifest, :status, :reason, :instance, keyword_init: true) do
      def id = manifest.id
      def version = manifest.version
      def compatible? = status == :compatible || status == :enabled
      def enabled? = status == :enabled
    end

    attr_reader :records

    def self.build(root: Rails.root.join("plugins"), core_version: (CinelarTV::Application::Version::FULL rescue "0.0.1"), frontend_api_version: "1.0.0")
      manifests = Dir.children(root).filter_map do |entry|
        directory = File.join(root, entry)
        next unless File.directory?(directory)
        next unless File.exist?(File.join(directory, "plugin.rb")) || File.exist?(File.join(directory, "plugin.json"))
        Manifest.from_directory(directory)
      rescue JSON::ParserError => e
        Manifest.new(directory, { "id" => entry, "version" => "0.0.0", "parse_error" => e.message })
      end
      new(manifests, core_version:, frontend_api_version:)
    end

    def initialize(manifests, core_version:, frontend_api_version:)
      @core_version = core_version
      @frontend_api_version = frontend_api_version
      @records = manifests.map { |manifest| Record.new(manifest:, status: :discovered) }
      validate!
    end

    def activate!
      ordered.each do |record|
        next unless record.manifest.backend_entry
        instance = Plugin::Instance.parse_from_source(record.manifest.plugin_rb_path)
        instance.activate!
        record.instance = instance
        record.status = :enabled
      rescue StandardError => e
        record.status = :failed
        record.reason = e.message
        Rails.logger.error("[PluginRegistry] Failed to activate #{record.id}: #{e.message}")
      end
      self
    end

    def ordered
      @ordered || []
    end

    def frontend_records
      ordered.select(&:enabled?).filter_map do |record|
        entry = record.manifest.frontend_entry
        next unless entry
        { id: record.id, version: record.version, entry: entry, dependencies: record.manifest.dependencies }
      end
    end

    private

    def validate!
      seen = {}
      records.each do |record|
        if !record.manifest.valid?
          record.status = :blocked
          record.reason = "invalid plugin manifest"
        elsif seen[record.id]
          record.status = :blocked
          record.reason = "duplicate plugin id #{record.id}"
        else
          seen[record.id] = true
          record.status = compatible_core?(record.manifest) ? :compatible : :blocked
          record.reason = "incompatible core or frontend API version" if record.status == :blocked
        end
      end

      resolution = DependencyResolver.new(records).resolve
      resolution.blocked.each do |id, reason|
        record = records.find { |candidate| candidate.id == id }
        record.status = :blocked
        record.reason = reason
      end
      @ordered = resolution.ordered.select(&:compatible?)
    end

    def compatible_core?(manifest)
      satisfies?(manifest.core_requirement, @core_version) && satisfies?(manifest.frontend_api_requirement, @frontend_api_version)
    end

    def satisfies?(requirement, version)
      DependencyResolver.satisfies?(version, requirement)
    end
  end
end
