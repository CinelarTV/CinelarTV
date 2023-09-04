# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :reload_storage_config
  before_action :require_finish_installation?

  before_action do
    if current_user && current_user.is_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  # Crea un before_action, si el usuario está logueado, pero no tiene un perfil seleccionado, lo redirige a la página de selección de perfil.
  #before_action :check_profile_if_signed_in

  def index
  end

  def refresh_settings
    SiteSetting.reload_settings
    redirect_to app_path
  end

  def capybara_spin
    ## Fullscreen video https://www.youtube.com/embed/k-BBfhWLfAQ?si=hA_9OFUrrZba97CQ
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

  def current_profile
    return @current_profile if defined?(@current_profile)

    if user_signed_in? && session[:current_profile_id].present?
      @current_profile ||= current_user.profiles.find_by(id: session[:current_profile_id])
    end
  end

  helper_method :current_profile

  private

  def check_profile_if_signed_in
    # Ignore if request is POST or JSON format
    return if request.post? || request.format.json?
    @select_profile_path = "/profiles/select"
    return if request.path == @select_profile_path # Agrega esta línea para evitar el bucle
    if user_signed_in? && !current_profile
      redirect_to @select_profile_path # Cambia "select_profile_path" a la ruta adecuada
    end
  end

  def reload_storage_config
    Rails.logger.info("Reloading storage config")
    BaseUploader.configure_storage
  end

  def require_finish_installation?
    if SiteSetting.waiting_on_first_user && !request.path.start_with?("/finish-installation")
      redirect_to "/finish-installation"
    end
  end
end
