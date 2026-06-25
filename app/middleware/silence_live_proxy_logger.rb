# frozen_string_literal: true

class SilenceLiveProxyLogger
  LIVE_PROXY_PATH = "/live_proxy"

  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] == LIVE_PROXY_PATH || env["PATH_INFO"]&.start_with?("#{LIVE_PROXY_PATH}/")
      silence_logger(Rails.logger) do
        silence_logger(ActiveRecord::Base.logger) { @app.call(env) }
      end
    else
      @app.call(env)
    end
  end

  private

  def silence_logger(logger, &block)
    return block.call unless logger&.respond_to?(:silence)

    logger.silence(Logger::ERROR, &block)
  end
end
