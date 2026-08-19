# frozen_string_literal: true

module Admin
  class PluginsController < Admin::BaseController
    def index
      registry = Rails.configuration.x.plugin_registry

      plugins = if registry
        registry.records.map { |record| plugin_payload(record) }
      else
        []
      end

      respond_to do |format|
        format.html
        format.json { render json: { plugins: plugins } }
      end
    end

    def toggle
      registry = Rails.configuration.x.plugin_registry
      record = registry&.records&.find { |r| r.id == params[:id] }

      unless record
        return render json: { error: "Plugin not found" }, status: :not_found
      end

      setting_name = record.instance&.send(:enabled_site_setting) || extract_enabled_site_setting(record.manifest)

      unless setting_name
        return render json: { error: "Plugin does not support toggling" }, status: :unprocessable_entity
      end

      unless SiteSetting.respond_to?(setting_name)
        return render json: { error: "Site setting #{setting_name} not found" }, status: :unprocessable_entity
      end

      current_value = SiteSetting.send(setting_name)
      SiteSetting.send("#{setting_name}=", !current_value)

      render json: {
        id: record.id,
        enabled_site_setting: setting_name,
        enabled: SiteSetting.send(setting_name)
      }
    end

    private

    def plugin_payload(record)
      manifest = record.manifest
      instance = record.instance
      setting_name = instance&.send(:enabled_site_setting) || extract_enabled_site_setting(manifest)

      {
        id: record.id,
        version: record.version,
        status: record.status.to_s,
        reason: record.reason,
        enabled: record.enabled?,
        compatible: record.compatible?,
        description: plugin_description(manifest, setting_name),
        enabled_site_setting: setting_name,
        has_backend: manifest.backend_entry.present?,
        has_frontend: manifest.frontend_entry.present?,
        backend_engine: manifest.data.dig("backend", "engine"),
        backend_routes: manifest.data.dig("backend", "routes"),
        backend_migrations: manifest.data.dig("backend", "migrations"),
      }
    end

    def extract_enabled_site_setting(manifest)
      plugin_rb = manifest.plugin_rb_path
      return nil unless plugin_rb && File.exist?(plugin_rb)

      source = File.read(plugin_rb)
      match = source.match(/^enabled_site_setting\s+:(\w+)/)
      match[1].to_sym if match
    end

    def plugin_description(manifest, setting_name)
      description = manifest.data["description"]
      return description if description.present?

      if setting_name && SiteSetting.respond_to?(:defined_fields)
        field = SiteSetting.defined_fields.find { |f| f[:key].to_s == setting_name.to_s }
        return field.dig(:options, :description) if field
      end

      nil
    end
  end
end
