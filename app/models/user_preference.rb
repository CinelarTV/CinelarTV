# frozen_string_literal: true

class UserPreference
  SCHEMA_PATH = Rails.root.join("config", "user_preferences.yml")

  class << self
    def schema
      @schema ||= load_schema
    end

    def reload_schema!
      @schema = load_schema
    end

    def all_settings
      @all_settings ||= build_settings_list
    end

    def settings_for_access(profile_type)
      all_settings.select do |setting|
        access = setting[:profile_access]
        access == "all" || (access == "owner_only" && profile_type == "OWNER")
      end
    end

    def get(profile, key)
      setting = all_settings.find { |s| s[:key] == key.to_s }
      return nil unless setting

      pref = profile.preferences.find_by(key: key)
      value = pref ? pref.value : setting[:default]

      cast_value(value, setting[:type])
    end

    def set(profile, key, value)
      setting = all_settings.find { |s| s[:key] == key.to_s }
      return { error: "Unknown preference: #{key}" } unless setting

      unless accessible?(setting, profile.profile_type)
        return { error: "Not authorized to set preference: #{key}" }
      end

      validation = validate_value(value, setting)
      return validation unless validation[:valid]

      normalized = normalize_value(value, setting[:type])
      pref = profile.preferences.find_or_initialize_by(key: key)
      pref.value = normalized
      pref.save

      { success: true, key: key, value: cast_value(normalized, setting[:type]) }
    end

    def set_batch(profile, preferences_hash)
      errors = []
      results = []

      preferences_hash.each do |key, value|
        result = set(profile, key, value)
        if result[:error]
          errors << result[:error]
        else
          results << result
        end
      end

      { results: results, errors: errors }
    end

    def accessible?(setting, profile_type)
      access = setting[:profile_access]
      return true if access == "all"
      return true if access == "owner_only" && profile_type == "OWNER"

      false
    end

    def settings_for_category(category)
      all_settings.select { |s| s[:category] == category }
    end

    def categories
      schema.keys
    end

    private

    def load_schema
      YAML.load_file(SCHEMA_PATH)
    end

    def build_settings_list
      settings = []
      schema.each do |category, category_settings|
        category_settings.each do |key, options|
          settings << {
            key: key.to_s,
            category: category.to_s,
            type: options["type"] || "string",
            default: options["default"],
            client: options["client"] || false,
            profile_access: options["profile_access"] || "all",
            readonly: options["readonly"] || false,
            allowed_values: options["allowed_values"],
            min: options["min"],
            max: options["max"],
            regex: options["regex"],
            maxlength: options["maxlength"]
          }
        end
      end
      settings
    end

    def cast_value(value, type)
      return nil if value.nil?

      case type
      when "boolean"
        %w[true 1 yes on].include?(value.to_s.downcase)
      when "integer"
        value.to_i
      when "number"
        value.to_f
      else
        value.to_s
      end
    end

    def normalize_value(value, type)
      case type
      when "boolean"
        cast_value(value, type) ? "true" : "false"
      when "integer"
        value.to_i.to_s
      when "number"
        value.to_f.to_s
      else
        value.to_s
      end
    end

    def validate_value(value, setting)
      type = setting[:type]
      return { valid: true } if type == "action"

      key = setting[:key]

      case type
      when "boolean"
        unless %w[true false 1 0].include?(value.to_s.downcase)
          return { error: "Invalid boolean value: #{key}" }
        end
      when "string"
        if setting[:maxlength] && value.to_s.length > setting[:maxlength]
          return { error: "Value too long: #{key} (max #{setting[:maxlength]})" }
        end
        if setting[:regex] && value.present?
          regex = Regexp.new(setting[:regex])
          unless value.to_s.match?(regex)
            return { error: "Invalid format: #{key}" }
          end
        end
      when "integer"
        unless value.to_s.match?(/\A-?\d+\z/)
          return { error: "Invalid integer value: #{key}" }
        end
        if setting[:min] && value.to_i < setting[:min]
          return { error: "Value too small: #{key} (min #{setting[:min]})" }
        end
        if setting[:max] && value.to_i > setting[:max]
          return { error: "Value too large: #{key} (max #{setting[:max]})" }
        end
      when "enum"
        if setting[:allowed_values] && !setting[:allowed_values].include?(value.to_s)
          return { error: "Invalid value: #{key}" }
        end
      end

      { valid: true }
    end
  end
end
