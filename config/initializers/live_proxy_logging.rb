# frozen_string_literal: true

require Rails.root.join("lib", "quiet_live_proxy_rack_logger")

Rails.application.config.middleware.swap(Rails::Rack::Logger, QuietLiveProxyRackLogger)
