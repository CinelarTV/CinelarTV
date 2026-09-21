# frozen_string_literal: true

module Auth
  class GoogleAuthenticator < Authenticator
    PROVIDER = "google_oauth2"

    def name
      "google_oauth2"
    end

    def enable_setting
      :enable_google_login
    end

    def required_settings
      %i[google_oauth2_client_id google_oauth2_client_secret]
    end

    def register_middleware(omniauth)
      omniauth.provider :google_oauth2,
                         setup: ->(env) {
                           strategy = env["omniauth.strategy"]
                           strategy.options[:client_id] = SiteSetting.google_oauth2_client_id
                           strategy.options[:client_secret] = SiteSetting.google_oauth2_client_secret
                           strategy.options[:scope] = SiteSetting.google_oauth2_scope
                         }
    end

    def after_authenticate(auth_hash)
      result = Auth::Result.new
      result.email = auth_hash.dig("info", "email")
      result.name = auth_hash.dig("info", "name")
      result.username = auth_hash.dig("info", "nickname") ||
                        result.email&.split("@")&.first
      result.email_valid = auth_hash.dig("info", "email_verified") != false
      result.uid = auth_hash["uid"]
      result.access_token = auth_hash.dig("credentials", "token")
      result.refresh_token = auth_hash.dig("credentials", "refresh_token")
      result.extra_data = auth_hash["extra"] || {}
      result
    end

    def find_or_create_user(result)
      return nil unless result.email.present?

      # 1. Existing identity linked
      identity = OauthIdentity.find_by(provider: PROVIDER, uid: result.uid)
      if identity&.user
        update_identity_tokens(identity, result)
        return identity.user
      end

      # 2. Auto-link by email if allowed
      if can_connect_existing_user?
        user = User.find_by(email: result.email.downcase)
        if user
          link_identity(user, result)
          return user
        end
      end

      # 3. New registration (respect allow_registration)
      return nil unless SiteSetting.allow_registration

      create_new_user(result)
    end

    def link_identity(user, result)
      identity = OauthIdentity.find_or_initialize_by(provider: PROVIDER, uid: result.uid)
      identity.update!(
        user: user,
        access_token: result.access_token,
        refresh_token: result.refresh_token,
        extra_data: result.extra_data
      )
    end

    private

    def create_new_user(result)
      password = SecureRandom.hex(16)
      user = User.new(
        email: result.email.downcase,
        username: result.username,
        password: password,
        password_confirmation: password,
        confirmed_at: SiteSetting.omniauth_auto_confirm_email ? Time.current : nil
      )

      if user.save
        link_identity(user, result)
        user
      else
        nil
      end
    end

    def update_identity_tokens(identity, result)
      identity.update(
        access_token: result.access_token,
        refresh_token: result.refresh_token
      )
    end
  end
end
