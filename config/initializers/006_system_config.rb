# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Rails.application.configure do
    #  config.force_ssl = SiteSettings.force_https
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.load_path += Dir[Rails.root.join("plugins", "*", "config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = SiteSetting.default_locale
    config.i18n.fallbacks = [:en]


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
    Logster.config.rate_limit_error_reporting = false 

    Logster.config.project_directories = [
      {
        path: Rails.root.to_s,
        url: "https://github.com/CinelarTV/CinelarTV-AIO",
        main_app: true,
      },
    ]

    if Rails.env.production?
      Logster.store.ignore = [
        # These errors are caused by client requests. No need to log them.
        # Rails itself defines these as 'silent exceptions', but this does
        # not entirely prevent them from being logged
        # https://github.com/rails/rails/blob/f2caed1e/actionpack/lib/action_dispatch/middleware/exception_wrapper.rb#L39-L42
      #  /^ActionController::RoutingError \(No route matches/,
        /^ActionDispatch::Http::MimeNegotiation::InvalidType/,
        /^PG::Error: ERROR:\s+duplicate key/,
        /^ActionController::UnknownFormat/,
        /^ActionController::UnknownHttpMethod/,
       # /^AbstractController::ActionNotFound/,
        # ignore any empty JS errors that contain blanks or zeros for line and column fields
        #
        # Line:
        # Column:
        #
        /(?m).*?Line: (?:\D|0).*?Column: (?:\D|0)/,
        # suppress empty JS errors (covers MSIE 9, etc)
        /^(Syntax|Script) error.*Line: (0|1)\b/m,
        # CSRF errors are not providing enough data
        # suppress unconditionally for now
        /^Can't verify CSRF token authenticity.$/,
        # related to browser plugins somehow, we don't care
        /Error calling method on NPObject/,
        # 404s can be dealt with elsewhere
        /^ActiveRecord::RecordNotFound/,
        # bad asset requested, no need to log
        /^ActionController::BadRequest/,
        # we can't do anything about invalid parameters
        /Rack::QueryParser::InvalidParameterError/,
      ]
      Logster.config.env_expandable_keys.push(:hostname)
    end

Logster.set_environments([:development, :production])
  end
end
