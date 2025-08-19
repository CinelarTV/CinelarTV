# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JsonError

  SKIPPABLE_PATHS = [
    "/finish-installation",
    "/manifest.webmanifest",
    "/capybara_spin",
    "/capybara",
    # Agrega aquí otros paths que quieras omitir
  ].freeze

  before_action :reload_storage_config
  before_action :require_finish_installation?
  before_action :check_maintenance_mode
  # Skip the CSRF token for API requests
  skip_before_action :verify_authenticity_token, if: :is_app_request?

  before_action do
    Rack::MiniProfiler.authorize_request if current_user&.is_admin?
  end

  # Crea un before_action, si el usuario está logueado, pero no tiene un perfil seleccionado, lo redirige a la página de selección de perfil.
  before_action :check_profile_if_signed_in

  def index; end

  def refresh_settings
    SiteSetting.reload_settings
    redirect_to app_path
  end

  def capybara_spin
    ## Fullscreen video https://www.youtube.com/embed/k-BBfhWLfAQ?si=hA_9OFUrrZba97CQ
    respond_to do |format|
      format.html do
        render html: '
        <title>CinelarTV</title>
        <iframe width="100%" height="100%" src="https://www.youtube.com/embed/k-BBfhWLfAQ?autoplay=1&controls=0&showinfo=0&autohide=1&loop=1" frameborder="0" allowfullscreen></iframe>
        <style>
        html, body {
          margin: 0;
          padding: 0;
          overflow: hidden;
        }
        </style>
        '.html_safe
      end
      format.json do
        render json: {
          message: "Capybara 🦦",
        }
      end
    end
  end

  def using_doorkeeper?
    defined?(doorkeeper_token) && doorkeeper_token&.resource_owner_id.present?
  end

  def current_profile
    return @current_profile if defined?(@current_profile)

    profile_id = if using_doorkeeper?
                   CinelarTV.cache.read("profile_#{doorkeeper_token.token}")
                 else
                   session[:current_profile_id]
                 end

    Rails.logger.debug "DEBUG current_profile_id: \\#{profile_id} (doorkeeper: \\#{using_doorkeeper?})"

    if current_user && profile_id.present?
      @current_profile = current_user.profiles.find_by(id: profile_id)
    end

    @current_profile
  end

  def is_app_request?
    request.format.json?
  end

  def authenticate_user!
    if doorkeeper_token
      doorkeeper_authorize!
    else
      super
    end
  end

  def current_user
    Rails.logger.info "DEBUG current_user: doorkeeper_token=#{doorkeeper_token.inspect}"

    if doorkeeper_token
      Rails.logger.info "DEBUG Token ID: #{doorkeeper_token.id}"
      Rails.logger.info "DEBUG Token resource_owner_id: #{doorkeeper_token.resource_owner_id}"
      Rails.logger.info "DEBUG Token created_at: #{doorkeeper_token.created_at}"
      Rails.logger.info "DEBUG Token expires_in: #{doorkeeper_token.expires_in}"
      Rails.logger.info "DEBUG Token revoked?: #{doorkeeper_token.revoked?}"
      Rails.logger.info "DEBUG Token application: #{doorkeeper_token.application_id}"
    end

    @current_user ||= if doorkeeper_token&.resource_owner_id.present?
                        user = User.find_by(id: doorkeeper_token.resource_owner_id)
                        Rails.logger.info "DEBUG Usuario encontrado: #{user&.id} - #{user&.email}"
                        user
                      else
                        Rails.logger.error "ERROR: Token válido pero sin resource_owner_id!"
                        super
                      end
  end

  rescue_from CinelarTV::NotFound do |e|
    rescue_actions(
      :not_found,
      e.status,
      original_path: e.original_path,
      custom_message: e.custom_message
    )
  end

  def rescue_actions(type, status_code, opts = nil)
    opts ||= {}
    show_json_errors =
      request.format&.json? || request.xhr?

    if show_json_errors
      render json: create_errors_json(type, opts), status: status_code
    else
      render "exceptions/#{status_code}", status: status_code, layout: "application"
    end
  end

  helper_method :current_profile

  private

  def check_profile_if_signed_in
    # Ignore if request is POST or JSON format
    return if request.post? || request.format.json?

    @select_profile_path = "/profiles/select"
    return if request.path == @select_profile_path # Agrega esta línea para evitar el bucle

    return unless user_signed_in? && !current_profile

    redirect_to @select_profile_path # Cambia "select_profile_path" a la ruta adecuada
  end

  def reload_storage_config
    Rails.logger.info("Reloading storage config")
    BaseUploader.configure_storage
  end

  def require_finish_installation?
    return false unless SiteSetting.waiting_on_first_user && SKIPPABLE_PATHS.none? do |path|
      request.path.start_with?(path)
    end

    redirect_to "/finish-installation", status: 302
    true
  end

  def check_maintenance_mode # rubocop:disable Naming/PredicateMethod
    # Solo admins pueden evitar el modo mantenimiento
    # Si es html, renderiza, si es json devuelve error json
    # Skippable paths no aplica aqui
    return false unless CinelarTV.maintenance_enabled
    return false if current_user&.is_admin?

    if request.format.json? || request.xhr?
      render json: { error: "El sitio está en mantenimiento. Por favor, inténtalo más tarde." },
             status: :service_unavailable
    else
      render template: "exceptions/maintenance", layout: "maintenance", status: :service_unavailable
    end
    true
  end
end
