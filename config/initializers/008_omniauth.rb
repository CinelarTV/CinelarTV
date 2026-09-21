# frozen_string_literal: true

require Rails.root.join("lib/middleware/omniauth_bypass_middleware").to_s

# Register the bypass middleware.  It sits at the very bottom of the
# Rack stack (wraps the Rails app directly) and only activates for
# /auth/* paths, building the provider stack on the fly.
#
# REQUIRES: User model must NOT include :omniauthable.  Devise's :omniauthable
# inserts its own (empty) OmniAuth::Builder middleware which intercepts /auth/*
# before this one can, then falls through to the Rails router → RoutingError.
# See app/models/user.rb and the comment in OmniauthBypassMiddleware.
Rails.application.config.middleware.use Middleware::OmniauthBypassMiddleware

OmniAuth.config.logger = Rails.logger
OmniAuth.config.silence_get_warning = true

# omniauth-rails_csrf_protection is installed and registers its own
# before_request_phase Railtie that validates CSRF tokens on POST requests.
# We disable OmniAuth's *own* request_validation_phase (which is separate and
# would run in addition to the gem's hook) to avoid double-validation.
OmniAuth.config.request_validation_phase = nil

OmniAuth.config.before_request_phase do |env|
  request = ActionDispatch::Request.new(env)

  # Store reconnect / origin hints in the session for the callback phase.
  request.session[:auth_reconnect] = !!request.params["reconnect"]
  if request.params["origin"].present?
    request.session[:destination_url] = request.params["origin"]
  end
end

OmniAuth.config.on_failure do |env|
  OmniAuth::FailureEndpoint.call(env)
end

# Required for callback URLs to resolve correctly behind proxies/tunnels.
OmniAuth.config.full_host = proc { |env|
  request = ActionDispatch::Request.new(env)
  "#{request.protocol}#{request.host_with_port}"
}
