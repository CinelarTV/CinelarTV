# frozen_string_literal: true

# app/models/site_setting.rb
class SiteSetting < RailsSettings::Base
  class << self
    def load_settings
      settings_yaml = Rails.root.join("config", "site_settings.yml")
      if File.exist?(settings_yaml)
        settings = YAML.load_file(settings_yaml)
        settings.each do |category, settings_data|
          scope category.to_sym do
            settings_data.each do |key, options|
              field key.to_sym,
                    default: options["default"] || ENV["CINELAR_#{key.upcase}"],
                    type: options["type"],
                    exposed_to_client: options["client"] || false,
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
                default: ENV["CINELAR_DEVELOPER_EMAILS"], # This is a comma-separated list of emails
                type: :string
        end
      end
    end

    def exposed_settings
      settings = {}
      defined_fields.each do |field|
        field_options = field[:options]
        if field_options && field_options[:exposed_to_client]
          settings[field[:key]] = send(field[:key])
        end
      end
      settings
    end

    def reload_settings
      clear_cache
    end

    private

    def default_waiting_on_first_user_value
      begin
        !User.exists?
      rescue ActiveRecord::NoDatabaseError
        true
      end
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
      if hidden_option.is_a?(String) && respond_to?(hidden_option)
        return send(hidden_option)
      end

      if hidden_option.is_a?(Proc)
        return hidden_option.call
      end

      false
    end
  end

  load_settings
end
