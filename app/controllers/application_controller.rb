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

    profile_id = using_doorkeeper? ? CinelarTV.cache.read("profile_#{doorkeeper_token.token}") : session[:current_profile_id]

    @current_profile = current_user&.profiles&.find_by(id: profile_id) if profile_id.present?
    @current_profile
  end

  def is_app_request?
    request.format.json?
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

    redirect_to "/profiles/select"
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
end