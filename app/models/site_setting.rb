# frozen_string_literal: true

# app/models/site_setting.rb
class SiteSetting < RailsSettings::Base
  class << self
    def load_settings
      settings_yaml = Rails.root.join("config", "site_settings.yml")
      return unless File.exist?(settings_yaml)

      settings = YAML.load_file(settings_yaml)

      # Merge de settings de plugins
      Dir.glob(Rails.root.join("plugins", "*", "config", "site_settings.yml")).each do |plugin_settings|
        plugin_yaml = YAML.load_file(plugin_settings)
        # Si el plugin no tiene categoría, lo mete bajo 'plugins'
        if plugin_yaml.is_a?(Hash) && !plugin_yaml.keys.first.is_a?(String)
          plugin_yaml = { 'plugins' => plugin_yaml }
        elsif plugin_yaml.is_a?(Hash) && (plugin_yaml.keys & settings.keys).empty?
          # Si no hay colisión de categorías, lo mete bajo 'plugins'
          plugin_yaml = { 'plugins' => plugin_yaml } unless plugin_yaml.keys.include?('plugins')
        end
        settings.deep_merge!(plugin_yaml) if plugin_yaml
      end

      settings.each do |category, settings_data|
        scope category.to_sym do
          settings_data.each do |key, options|
            field key.to_sym,
                  default: options["default"] || ENV.fetch("CINELAR_#{key.upcase}", nil),
                  type: options["type"],
                  exposed_to_client: options["client"] || false,
                  refresh: options["refresh"] || false,
                  readonly: options["readonly"] || false,
                  allowed_values: options["allowed_values"] || nil,
                  hidden: options["hidden"] || false
          end
        end
      end

      # Set internal settings

      scope :internal do
        field :waiting_on_first_user,
              default: -> { default_waiting_on_first_user_value },
              type: :boolean

        field :developer_emails,
              default: ENV.fetch("CINELAR_DEVELOPER_EMAILS", nil), # This is a comma-separated list of emails
              type: :string
      end
    end

    def exposed_settings
      settings = {}
      defined_fields.each do |field|
        field_options = field[:options]
        settings[field[:key]] = send(field[:key]) if field_options && field_options[:exposed_to_client]
      end
      settings
    end

    def reload_settings
      clear_cache
    end

    private

    def default_waiting_on_first_user_value
      !User.exists?
    rescue ActiveRecord::NoDatabaseError
      true
    end

    def build_validators(options)
      validator_names = options.split("|")
      puts "Building validators with options #{options}"
      validator_names.map { |name| build_validator(name, options) }
    end

    def build_validator(name, options)
      puts "Building validator #{name} with options #{options}"
      case name
      when "allowed_values"
        AllowedValuesValidator.new(allowed_values: options["allowed_values"])
      when "presence"
        { presence: true }
      end
    end

    def hide_setting?(options)
      hidden_option = options[:hidden]
      return false unless hidden_option
      return send(hidden_option) if hidden_option.is_a?(String) && respond_to?(hidden_option)

      return hidden_option.call if hidden_option.is_a?(Proc)

      false
    end
  end

  load_settings
end
