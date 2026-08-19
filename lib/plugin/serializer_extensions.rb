# frozen_string_literal: true

module Plugin
  # Allows plugins to conditionally add attributes to existing serializers
  # without monkey-patching. Each extension records the serializer class,
  # attribute name, an optional condition block, a value block, and the
  # owning plugin.
  #
  # Usage from a plugin's plugin.rb:
  #
  #   register_serializer_extension(
  #     ContentSerializer,
  #     :watch_party_active,
  #     if: -> { WatchParty::Session.active.exists?(content_id: object.id) }
  #   ) do |content, _scope, _options|
  #     WatchParty::Session.active.where(content_id: content.id).count
  #   end
  #
  class SerializerExtension
    attr_reader :serializer_class, :attribute_name, :plugin_name, :condition, :block

    def initialize(serializer_class, attribute_name, plugin_name:, condition: nil, &block)
      @serializer_class = serializer_class
      @attribute_name = attribute_name
      @plugin_name = plugin_name
      @condition = condition
      @block = block
    end

    def enabled?(object, scope, options)
      return true if @condition.nil?
      @condition.call(object, scope, options)
    end
  end

  # Thread-safe registry for serializer extensions.
  module SerializerExtensionRegistry
    MUTEX = Mutex.new

    class << self
      def register(serializer_class, attribute_name, plugin_name:, condition: nil, &block)
        ext = SerializerExtension.new(serializer_class, attribute_name,
                                       plugin_name: plugin_name,
                                       condition: condition, &block)
        MUTEX.synchronize { extensions << ext }
        ext
      end

      def extensions_for(serializer_class)
        MUTEX.synchronize { extensions.select { |e| e.serializer_class == serializer_class } }
      end

      def remove_by_plugin(plugin_name)
        MUTEX.synchronize { extensions.reject! { |e| e.plugin_name == plugin_name } }
      end

      def clear!
        MUTEX.synchronize { @extensions = [] }
      end

      private

      def extensions
        @extensions ||= []
      end
    end
  end
end

# Integrate into ActiveModel::Serializer. The override is minimal: it only
# allocates when extensions exist for the serializer's class.
ActiveModel::Serializer.class_eval do
  alias_method :_original_as_json, :as_json unless method_defined?(:_original_as_json)

  def as_json(options = nil)
    result = _original_as_json(options)

    extensions = Plugin::SerializerExtensionRegistry.extensions_for(self.class)
    return result unless extensions.any?

    opts = options || instance_options || {}
    scope = opts[:scope] || (respond_to?(:scope) ? self.scope : nil)
    result = result.dup if result.is_a?(Hash)

    extensions.each do |ext|
      next unless ext.enabled?(object, scope, opts)
      value = ext.block.call(object, scope, opts)
      result[ext.attribute_name] = value
    end

    result
  end
end
