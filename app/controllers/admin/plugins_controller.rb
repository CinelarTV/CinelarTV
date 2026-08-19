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

    private

    def plugin_payload(record)
      manifest = record.manifest
      {
        id: record.id,
        version: record.version,
        status: record.status.to_s,
        reason: record.reason,
        enabled: record.enabled?,
        compatible: record.compatible?,
        has_backend: manifest.backend_entry.present?,
        has_frontend: manifest.frontend_entry.present?,
        backend_engine: manifest.data.dig("backend", "engine"),
        backend_routes: manifest.data.dig("backend", "routes"),
        backend_migrations: manifest.data.dig("backend", "migrations"),
      }
    end
  end
end
