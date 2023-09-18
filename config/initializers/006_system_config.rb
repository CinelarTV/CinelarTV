# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Rails.application.configure do
    #  config.force_ssl = SiteSettings.force_https
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = SiteSetting.default_locale

    config.hosts << [
      ENV["CINELAR_BASE_URL"],
      SiteSetting.base_url,
    ]

    Logster.config.use_full_hostname = true
    # We have SiteSetting.enable_js_error_reporting, but only affect the client side
    # Keep enabled to expose /logs/reports_js_error endpoint
    Logster.config.enable_js_error_reporting = true
    Logster.config.enable_custom_patterns_via_ui = true
    Logster.config.application_version = CinelarTV.git_version
    Logster.config.web_title = "🍿 Log Viewer - CinelarTV AIO"

    Logster.config.project_directories = [
      {
        path: Rails.root.to_s,
        url: "https://github.com/CinelarTV/CinelarTV-AIO",
        main_app: true,
      },
    ]
    Logster.set_environments([:production])
  end
end
