# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JsonError

  SKIPPABLE_PATHS = [
    "/finish-installation",
    "/manifest.webmanifest",
    "/capybara_spin",
    "/capybara",
  ].freeze

  before_action :require_finish_installation?
  before_action :check_maintenance_mode
  skip_before_action :verify_authenticity_token, if: :is_app_request?

  before_action do
    Rack::MiniProfiler.authorize_request if current_user&.is_admin?
  end

  before_action :check_profile_if_signed_in
  before_action :ensure_account_active

  def index; end

  def refresh_settings
    SiteSetting.reload_settings
    redirect_to app_path
  end

  def capybara_spin
    respond_to do |format|
      format.html do
        render html: '
        <title>CinelarTV</title>
        <iframe width="100%" height="100%" src="https://www.youtube.com/embed/k-BBfhWLfAQ?autoplay=1&controls=0&showinfo=0&autohide=1&loop=1" frameborder="0" allowfullscreen></iframe>
        <style>html, body { margin: 0; padding: 0; overflow: hidden; }</style>
        '.html_safe
      end
      format.json { render json: { message: "Capybara 🦦" } }
    end
  end

  def using_doorkeeper?
    doorkeeper_token&.resource_owner_id.present?
  end

  def current_profile
    return @current_profile if defined?(@current_profile)

    profile_id = using_doorkeeper? ? doorkeeper_token.current_profile_id : session[:current_profile_id]

    @current_profile = current_user&.profiles&.find_by(id: profile_id) if profile_id.present?
    @current_profile
  end

  def is_app_request?
    request.format.json? || request.content_type == "application/json" || using_doorkeeper?
  end

  def authenticate_user!
    doorkeeper_token ? doorkeeper_authorize! : super
  end

  def current_user
    @current_user ||= if using_doorkeeper?
                        User.find_by(id: doorkeeper_token.resource_owner_id)
                      else
                        super
                      end
  end

  rescue_from CinelarTV::NotFound do |e|
    rescue_actions(:not_found, e.status, original_path: e.original_path, custom_message: e.custom_message)
  end

  def rescue_actions(type, status_code, opts = {})
    if request.format&.json? || request.xhr?
      render json: create_errors_json(type, opts), status: status_code
    else
      render "exceptions/#{status_code}", status: status_code, layout: "application"
    end
  end

  helper_method :current_profile

  private

  def check_profile_if_signed_in
    # This guard should only apply to page navigations, not mutating API requests.
    return unless request.get?
    return if request.format.json?
    return if request.path == "/profiles/select"
    return unless user_signed_in? && !current_profile

    session[:pending_return_to] = request.fullpath
    redirect_to "/profiles/select"
  end

  def ensure_account_active
    # Support both Devise session users and Doorkeeper bearer-token users.
    user = current_user

    # If there's no Devise session user, try to resolve a user from a valid
    # Doorkeeper bearer token present in the Authorization header. We only
    # accept tokens that exist and are not revoked/expired so we don't trust
    # stale tokens when checking account state.
    if user.nil?
      token_user = user_from_bearer_token
      if token_user
        @current_user = token_user
        user = token_user
      end
    end

    return unless user

    if user.deactivated?
      handle_inactive_account(:deactivated)
      return false
    end

    if user.suspended?
      handle_inactive_account(:suspended)
      return false
    end

    # Block users whose confirmation period has expired (7 days)
    if !user.confirmed? && user.confirmation_expired?
      handle_inactive_account(:unconfirmed)
      return false
    end

    true
  end

  def handle_inactive_account(type)
    if request.format.json? || request.xhr? || using_doorkeeper?
      message = if type == :unconfirmed
                  I18n.t('devise.failure.unconfirmed')
                elsif type == :deactivated
                  "La cuenta ha sido desactivada. Contacta con soporte."
                else
                  suspension_message
                end
      error_type = if type == :unconfirmed
                     'unconfirmed'
                   elsif type == :deactivated
                     'account_deactivated'
                   else
                     'account_suspended'
                   end
      render json: create_errors_json(message, type: error_type), status: :forbidden
    else
      sign_out(current_user) if defined?(sign_out)
      alert_message = if type == :unconfirmed
                       I18n.t('devise.failure.unconfirmed')
                     elsif type == :deactivated
                       'Tu cuenta ha sido desactivada.'
                     else
                       'Tu cuenta está suspendida.'
                     end
      redirect_to "/", alert: alert_message
    end
  end

  def suspension_message
    return 'Tu cuenta ha sido suspendida indefinidamente.' if current_user.suspended_indefinitely?
    return "Tu cuenta está suspendida hasta #{I18n.l(current_user.suspended_until)}." if current_user.suspended_temporary?

    'Tu cuenta está suspendida.'
  end

  def require_finish_installation?
    return false unless SiteSetting.waiting_on_first_user
    return false if SKIPPABLE_PATHS.any? { |path| request.path.start_with?(path) }

    redirect_to "/finish-installation", status: 302
    true
  end

  def check_maintenance_mode
    return false unless CinelarTV.maintenance_enabled
    return false if current_user&.is_admin?

    if request.format.json? || request.xhr?
      render json: { error: "El sitio está en mantenimiento. Por favor, inténtalo más tarde." }, status: :service_unavailable
    else
      render template: "exceptions/maintenance", layout: "maintenance", status: :service_unavailable
    end
    true
  end

  # Try to extract a bearer token from the Authorization header and resolve
  # a valid Doorkeeper access token -> user. Returns nil if none found or the
  # token is revoked/expired.
  def user_from_bearer_token
    token_str = bearer_token_from_header
    return nil unless token_str

    token = Doorkeeper::AccessToken.find_by(token: token_str)
    return nil unless token && token.resource_owner_id.present?
    return nil if token.revoked? || token.expired?

    User.find_by(id: token.resource_owner_id)
  rescue StandardError => e
    Rails.logger.error("user_from_bearer_token failed: #{e.class} - #{e.message}")
    nil
  end

  def bearer_token_from_header
    auth = request.headers['Authorization'] || request.headers['HTTP_AUTHORIZATION']
    return nil unless auth.present?
    m = auth.match(/\ABearer\s+(.+)\z/i)
    m && m[1]
  end

  def broadcast_profile_update(user, payload = {})
    return unless user

    channel = "/profiles/#{user.id}"
    begin
      MessageBus.publish(channel, payload)
    rescue => e
      Rails.logger.error("broadcast_profile_update failed for #{channel}: #{e.message}")
    end
  end
end