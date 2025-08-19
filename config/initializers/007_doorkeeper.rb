# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # ------------------------------
  # Autenticación del Resource Owner
  # ------------------------------
resource_owner_authenticator do
  Rails.logger.debug "DEBUG current_user en authenticator: #{current_user&.id}"
  Rails.logger.debug "DEBUG warden user: #{warden.user}"
  
  # Intenta obtener el usuario de diferentes formas
  user = current_user || warden.user || warden.authenticate!(scope: :user)
  
  Rails.logger.debug "DEBUG usuario final: #{user&.id}"
  user
end 

  resource_owner_from_credentials do |_routes|
    Rails.logger.debug "[Doorkeeper] Params recibidos: #{params.inspect}"
    user = User.find_for_database_authentication(email: params[:username] || params[:email])
    Rails.logger.debug "[Doorkeeper] Buscando usuario con email o username: #{params[:username] || params[:email]}"
    Rails.logger.debug "[Doorkeeper] Usuario encontrado: #{user.inspect}"

    if user&.valid_for_authentication? { user.valid_password?(params[:password]) } &&
       user&.active_for_authentication?
      Rails.logger.debug "[Doorkeeper] Usuario autenticado y activo: #{user.id}"
      request.env['warden'].set_user(user, scope: :user, store: false)
      user
    else
      Rails.logger.debug "[Doorkeeper] Falló autenticación o usuario inactivo"
    end
  end

  # ------------------------------
  # Autenticación del Admin
  # ------------------------------
  admin_authenticator do
    if current_user&.has_role?(:admin)
      true
    else
      redirect_to new_user_session_url
      false
    end
  end

  # ------------------------------
  # Opciones de OAuth
  # ------------------------------
  # Generar refresh tokens
  use_refresh_token

  # Permitir URIs de redirección en blanco (ej: para device_code)
  allow_blank_redirect_uri true

  # Grant flows habilitados
  grant_flows %w[
    authorization_code
    client_credentials
    password
    device_code
  ]
end

