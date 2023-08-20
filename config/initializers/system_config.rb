# frozen_string_literal: true

Rails.application.reloader.to_prepare do
    Rails.application.configure do
      #  config.force_ssl = SiteSettings.force_https
      config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
      config.i18n.default_locale = SiteSetting.default_locale

      config.hosts << [
        ENV['CINELAR_BASE_URL'],
        SiteSetting.base_url,
      ]
  
      Logster.config.use_full_hostname = true
      Logster.config.enable_js_error_reporting = SiteSetting.enable_js_error_reporting
  
      Logster.config.project_directories = [
          {
              path: Rails.root.to_s,
              url: "https://github.com/CinelarTV/CinelarTV-AIO",
              main_app: true
          }
      ]
      Logster.set_environments([:production])
    end
  end