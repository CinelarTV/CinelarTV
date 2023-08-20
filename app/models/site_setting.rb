# frozen_string_literal: true

# app/models/site_setting.rb
class SiteSetting < RailsSettings::Base
  
  def self.load_settings
    settings_yaml = Rails.root.join('config', 'site_settings.yml')
    if File.exist?(settings_yaml)
      settings = YAML.load_file(settings_yaml)
      settings.each do |category, settings_data|
        scope category.to_sym do

        settings_data.each do |key, options|
          # Iterar sobre cada ajuste y añadirlo utilizando

          field key.to_sym,
          default: options["default"] || ENV["CINELAR_#{key.upcase}"],
          validates: { presence: true },
          type: options["type"],
          exposed_to_client: options["client"] || false,
          readonly: options["readonly"] || false
        end
        end
      end

    end
  end

  def self.exposed_settings
    settings = {}
  
    self.defined_fields.each do |field|
      field_options = field[:options]
      if field_options && field_options[:exposed_to_client]
        settings[field[:key]] = self.send(field[:key])
      end
    end
  
    settings
  end

  def self.reload_settings
    self.clear_cache
  end
  


  load_settings

  

end