# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include JsonError

  before_action :reload_storage_config
  before_action :require_finish_installation?

  before_action do
    Rack::MiniProfiler.authorize_request if current_user&.is_admin?
  end

  # Crea un before_action, si el usuario está logueado, pero no tiene un perfil seleccionado, lo redirige a la página de selección de perfil.
  # before_action :check_profile_if_signed_in

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

  def current_profile
    return @current_profile if defined?(@current_profile)

    return unless user_signed_in? && session[:current_profile_id].present?

    @current_profile ||= current_user.profiles.find_by(id: session[:current_profile_id])
  end

  rescue_from CinelarTV::NotFound do |e|
    rescue_actions(
      :not_found,
      e.status,
      original_path: e.original_path,
      custom_message: e.custom_message,
    )
  end

  def rescue_actions(type, status_code, opts = nil)
    opts ||= {}
    show_json_errors =
      (request.format && request.format.json?) || (request.xhr?)

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
    return false unless SiteSetting.waiting_on_first_user && !request.path.start_with?("/finish-installation")

    redirect_to "/finish-installation", status: 302
    true
  end
end
