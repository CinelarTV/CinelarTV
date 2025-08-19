# Configura CORS dinámicamente según SiteSetting
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if SiteSetting.enable_cors
      origins = SiteSetting.cors_allowed_origins.presence || '*'
      origins origins
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: false
    end
  end
end
