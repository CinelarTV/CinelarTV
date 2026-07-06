# frozen_string_literal: true

module PluginRegistry
  class << self
    def define_register(name, type)
      instance_variable_set(:"@#{name}", type.new)
      define_singleton_method(name) { instance_variable_get(:"@#{name}") }
      
      singular = name.to_s.singularize
      register_name = :"register_#{singular}"
      
      if type <= Hash
        define_singleton_method(register_name) do |key, value|
          instance_variable_get(:"@#{name}")[key] = value
        end
      else
        define_singleton_method(register_name) do |value|
          Rails.logger.info "[PluginRegistry] Registering #{singular}: #{value}"
          instance_variable_get(:"@#{name}") << value
        end
      end
    end

    def define_filtered_register(name)
      raw_name = :"@_raw_#{name.to_s.gsub(/[^a-zA-Z_]/, '_')}"
      instance_variable_set(raw_name, [])

      define_singleton_method(name) do
        instance_variable_get(raw_name)
          .filter_map { |h| h[:value] if h[:plugin].enabled? }
          .uniq
      end

      define_singleton_method("register_#{name.to_s.singularize}") do |value, plugin|
        instance_variable_get(raw_name) << { plugin: plugin, value: value }
      end
    end

    REGISTER_TYPES = {
      seed_data: ActiveSupport::HashWithIndifferentAccess.new,
    }.freeze

    def clear_all
      instance_variables.each do |var|
        if var.to_s.start_with?('@_raw_')
          instance_variable_set(var, [])
        elsif (type = REGISTER_TYPES[var.to_s.delete("@").to_sym])
          instance_variable_set(var, type.dup)
        end
      end
    end

    def reset!
      clear_all
      initialize_registers
    end

    private

    def initialize_registers
      # Static registers
      define_register :seed_data, ActiveSupport::HashWithIndifferentAccess

      # Filtered registers (only include values from enabled plugins)
      # CinelarTV specific registers based on codebase analysis
      define_filtered_register :user_profile_fields
      define_filtered_register :content_scopes
      define_filtered_register :admin_menu_items
      define_filtered_register :user_menu_items
      define_filtered_register :dashboard_widgets
      define_filtered_register :video_source_types
      define_filtered_register :live_tv_features
      define_filtered_register :subscription_providers
      define_filtered_register :content_metadata_fields
      define_filtered_register :player_controls
      define_filtered_register :search_filters
    end
  end

  # Initialize all registers
  reset!
end
