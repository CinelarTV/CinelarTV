# frozen_string_literal: true

# Skip Rails request-level info logs for the live proxy endpoint to avoid
# flooding logs with high-frequency segment requests.
class QuietLiveProxyRackLogger < Rails::Rack::Logger
  LIVE_PROXY_PATH = "/live_proxy"

  def call(env)
    request = ActionDispatch::Request.new(env)
    return @app.call(env) if request.path == LIVE_PROXY_PATH

    super
  end
end
