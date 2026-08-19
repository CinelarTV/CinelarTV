# frozen_string_literal: true

module Plugin
  class DependencyResolver
    Result = Struct.new(:ordered, :blocked, keyword_init: true)

    def initialize(records)
      @records = records.index_by(&:id)
      @blocked = {}
    end

    def resolve
      validate_dependencies
      visit_all
      Result.new(ordered: @ordered || [], blocked: @blocked)
    end

    private

    def validate_dependencies
      @records.each_value do |record|
        next unless record.compatible?

        record.manifest.dependencies.each do |name, requirement|
          next if name.start_with?("@cinelartv/")
          dependency = @records[name]
          if dependency.nil?
            block(record, "missing required plugin dependency #{name}")
          elsif !satisfies?(dependency.version, requirement)
            block(record, "plugin dependency #{name} #{requirement} is incompatible with #{dependency.version}")
          end
        end
      end
    end

    def visit_all
      @ordered = []
      @visiting = []
      @visited = {}
      @records.each_value { |record| visit(record) }
    end

    def visit(record)
      return if @visited[record.id] || @blocked.key?(record.id)
      if @visiting.include?(record.id)
        cycle = (@visiting.drop(@visiting.index(record.id)) + [record.id]).join(" -> ")
        @visiting.each { |id| block(@records[id], "cyclic plugin dependency: #{cycle}") }
        return
      end

      @visiting << record.id
      record.manifest.dependencies.each_key do |dependency_id|
        next if dependency_id.start_with?("@cinelartv/")
        visit(@records[dependency_id]) if @records[dependency_id]
      end
      @visiting.pop
      return if @blocked.key?(record.id)

      @visited[record.id] = true
      @ordered << record
    end

    def block(record, reason)
      @blocked[record.id] ||= reason
    end

    # Public version-check used by Registry without instantiation.
    def self.satisfies?(version, requirement)
      return true if requirement.blank? || requirement == "*"
      requirement.to_s.split(/\s+\|\|\s+/).any? do |alternative|
        Gem::Requirement.new(*npm_range(alternative).split(/\s+/)).satisfied_by?(Gem::Version.new(version))
      rescue ArgumentError
        false
      end
    end

    def self.npm_range(requirement)
      return requirement unless requirement.start_with?("^")
      version = Gem::Version.new(requirement.delete_prefix("^"))
      segments = version.segments
      upper = if segments[0].positive?
        "#{segments[0] + 1}.0.0"
      elsif segments[1].to_i.positive?
        "0.#{segments[1] + 1}.0"
      else
        "0.0.#{segments[2].to_i + 1}"
      end
      ">=#{version} <#{upper}"
    end

    private_class_method :npm_range

    # Gem::Requirement understands Ruby ranges, while plugin manifests use npm
    # caret ranges. Normalize only the syntax we document and fail closed.
    def satisfies?(version, requirement)
      return true if requirement.blank? || requirement == "*"
      normalized = requirement.to_s.split(/\s+\|\|\s+/).any? do |alternative|
        Gem::Requirement.new(*npm_range(alternative).split(/\s+/)).satisfied_by?(Gem::Version.new(version))
      rescue ArgumentError
        false
      end
      normalized
    end

    def npm_range(requirement)
      return requirement unless requirement.start_with?("^")
      version = Gem::Version.new(requirement.delete_prefix("^"))
      segments = version.segments
      upper = if segments[0].positive?
        "#{segments[0] + 1}.0.0"
      elsif segments[1].to_i.positive?
        "0.#{segments[1] + 1}.0"
      else
        "0.0.#{segments[2].to_i + 1}"
      end
      ">=#{version} <#{upper}"
    end
  end
end
