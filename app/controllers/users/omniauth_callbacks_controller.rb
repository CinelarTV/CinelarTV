# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < ApplicationController
    layout "no_spa"

    skip_before_action :verify_authenticity_token, only: %i[token_exchange]
    # The request phase (POST /auth/google_oauth2) is handled entirely by the
    # OmniAuth Rack middleware (Middleware::OmniauthBypassMiddleware), so Rails
    # routing + CSRF protection don't apply to it.
    # The callback phase (GET /auth/google_oauth2/callback) hits this controller
    # after OmniAuth has already done its work and populated env["omniauth.auth"].
    skip_before_action :verify_authenticity_token, only: %i[callback google_oauth2 failure]

    # Web Flow: GET /auth/:provider/callback
    def google_oauth2
      handle_provider_callback("google_oauth2")
    end

    # Generic endpoint used by the route-mounted OmniAuth Rack application.
    def callback
      handle_provider_callback(params[:provider])
    end

    # OmniAuth failure handler: GET /auth/failure?message=...
    def failure
      message = params[:message] || "Authentication failed"
      render_auth_error(message)
    end

    # Mobile Flow: POST /auth/:provider/token.json
    #
    # Expected params:
    #   id_token         - Google ID token (JWT) from the mobile SDK.
    #                      Verified cryptographically against Google's JWKS —
    #                      this is the correct way to assert identity server-side.
    #   server_auth_code - Optional one-time code (requires offlineAccess: true
    #                      in the mobile SDK). Needed only if you want to exchange
    #                      it for a refresh_token to call Google APIs from the
    #                      backend. For auth-only, id_token is sufficient.
    def token_exchange
      provider_name = params[:provider]
      authenticator = Auth::Registry.find_by_name(provider_name)

      unless authenticator&.enabled?
        render json: { error: "provider_disabled", message: "#{provider_name} login is not enabled" },
               status: :forbidden
        return
      end

      id_token = params[:id_token]
      unless id_token.present?
        render json: {
          error: "missing_id_token",
          message: "Provide the id_token returned by the mobile Google Sign-In SDK. " \
                   "Do not use access_token — it cannot securely verify identity server-side."
        }, status: :unprocessable_entity
        return
      end

      user_info = verify_provider_token(provider_name, id_token)
      unless user_info
        render json: { error: "invalid_token", message: "Could not verify token with provider" },
               status: :unauthorized
        return
      end

      auth_hash = build_auth_hash(provider_name, user_info, nil)
      result = authenticator.after_authenticate(auth_hash)
      user = authenticator.find_or_create_user(result)

      if user&.persisted?
        doorkeeper_token = create_doorkeeper_token(user)
        render json: {
          access_token: doorkeeper_token.token,
          refresh_token: doorkeeper_token.refresh_token,
          token_type: "Bearer",
          expires_in: doorkeeper_token.expires_in,
          created_at: doorkeeper_token.created_at,
          user: serialize_user(user, doorkeeper_token)
        }
      else
        render json: {
          error: "account_creation_failed",
          message: "Could not create or find account. Check if registration is allowed."
        }, status: :unprocessable_entity
      end
    end

    private

    def handle_provider_callback(provider_name)
      authenticator = Auth::Registry.find_by_name(provider_name)

      unless authenticator&.enabled?
        render_auth_error("#{provider_name} login is not enabled")
        return
      end

      auth_hash = request.env["omniauth.auth"]

      unless auth_hash
        render_auth_error("No authentication data received from provider")
        return
      end

      result = authenticator.after_authenticate(auth_hash)
      user = authenticator.find_or_create_user(result)

      if user&.persisted?
        sign_in(user)
        redirect_to root_path
      else
        render_auth_error("Could not authenticate you from #{provider_name}. Please verify your account.")
      end
    rescue => e
      Rails.logger.error("[OmniauthCallbacks] Error: #{e.class} - #{e.message}")
      render_auth_error("An unexpected error occurred during authentication.")
    end

    def render_auth_error(message)
      @error_message = message
      render :auth_error, status: :unprocessable_entity
    end

    def verify_provider_token(provider_name, id_token)
      case provider_name
      when "google_oauth2"
        verify_google_id_token(id_token)
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error("[OmniauthCallbacks] Token verification failed: #{e.class} - #{e.message}")
      nil
    end

    # Verify a Google ID token (JWT) by:
    #   1. Fetching Google's public JWKS
    #   2. Verifying the RS256 signature
    #   3. Checking aud, iss, exp claims
    #
    # This is the secure, recommended approach per Google's documentation.
    # Unlike calling /userinfo with an access_token, this does not require
    # a network call for every authentication (the JWKS can be cached).
    #
    # Reference: https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
    def verify_google_id_token(id_token)
      # Decode header to find the key ID (kid)
      header = JWT.decode(id_token, nil, false).last
      kid = header["kid"]

      jwks = fetch_google_jwks
      jwk = jwks["keys"].find { |k| k["kid"] == kid }

      unless jwk
        Rails.logger.error("[OmniauthCallbacks] No matching JWK found for kid=#{kid}")
        return nil
      end

      public_key = JWT::JWK.new(jwk).public_key

      payload, _header = JWT.decode(
        id_token,
        public_key,
        true,
        {
          algorithms: ["RS256"],
          iss: ["accounts.google.com", "https://accounts.google.com"],
          verify_iss: true,
          aud: SiteSetting.google_oauth2_client_id,
          verify_aud: true
        }
      )

      # email_verified must be true — Google issues tokens for unverified emails
      # in some edge cases (e.g. legacy G Suite accounts).
      unless payload["email_verified"]
        Rails.logger.warn("[OmniauthCallbacks] Google ID token has unverified email: #{payload['email']}")
        return nil
      end

      payload
    rescue JWT::ExpiredSignature
      Rails.logger.warn("[OmniauthCallbacks] Expired Google ID token")
      nil
    rescue JWT::DecodeError => e
      Rails.logger.warn("[OmniauthCallbacks] JWT decode error: #{e.message}")
      nil
    end

    # Fetch Google's public JWKS with a short in-memory cache (10 minutes).
    # Google rotates keys periodically but not frequently enough to skip caching.
    GOOGLE_JWKS_URI = "https://www.googleapis.com/oauth2/v3/certs"
    GOOGLE_JWKS_CACHE_TTL = 10.minutes

    def fetch_google_jwks
      cache_key = "google_oauth2_jwks"
      cached = Rails.cache.fetch(cache_key, expires_in: GOOGLE_JWKS_CACHE_TTL) do
        response = HTTParty.get(GOOGLE_JWKS_URI)
        raise "Failed to fetch Google JWKS: #{response.code}" unless response.success?
        response.parsed_response
      end
      cached
    end

    def build_auth_hash(provider_name, user_info, _access_token = nil)
      # user_info is the verified JWT payload from Google's ID token.
      # Field mapping: JWT claim → OmniAuth auth_hash structure.
      #   sub   → uid  (stable Google user identifier — use this, not email)
      #   email → info.email
      #   name  → info.name
      #   picture → info.image
      #   email_verified → info.email_verified
      {
        "provider" => provider_name,
        "uid"      => user_info["sub"],
        "info"     => {
          "email"          => user_info["email"],
          "name"           => user_info["name"],
          "nickname"       => user_info["email"]&.split("@")&.first,
          "image"          => user_info["picture"],
          "email_verified" => user_info["email_verified"]
        },
        "credentials" => {},
        "extra"       => { "raw_info" => user_info }
      }
    end

    def create_doorkeeper_token(user)
      Doorkeeper::AccessToken.create!(
        resource_owner_id: user.id,
        application: Doorkeeper::Application.first || create_default_application,
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: true
      )
    rescue StandardError => e
      Rails.logger.error("[OmniauthCallbacks] Failed to create token: #{e.class} - #{e.message}")
      nil
    end

    def create_default_application
      Doorkeeper::Application.create!(
        name: "Default API Client",
        uid: SecureRandom.hex(16),
        secret: SecureRandom.hex(32),
        redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
        scopes: "read write"
      )
    end

    def serialize_user(user, token)
      CurrentUserSerializer.new(user, {
        include_profiles: true,
        current_profile_id: nil
      }).as_json
    end
  end
end
