# frozen_string_literal: true

# API V1 Authentication Controller
# Designed for mobile/native clients (iOS, Android, etc.)
#
# Flow for mobile clients:
# 1. POST /api/v1/auth/login - Get access_token + refresh_token
# 2. GET /api/v1/auth/me - Get current user with profiles (requires Bearer token)
# 3. GET /api/v1/auth/profile-status - Check if profile is selected
# 4. POST /api/v1/auth/select-profile - Select active profile
# 5. DELETE /api/v1/auth/logout - Revoke token and logout
#
# All endpoints return JSON. Protected endpoints require:
# Authorization: Bearer <access_token>
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_token!, only: %i[me logout profile_status select_profile deassign_profile]

      # POST /api/v1/auth/login
      # Authenticate user and return OAuth tokens
      #
      # Params:
      # - email or username: string (required)
      # - password: string (required)
      #
      # Response:
      # - access_token: Bearer token for API requests
      # - refresh_token: Token to refresh access_token when expired
      # - token_type: "Bearer"
      # - expires_in: Token TTL in seconds
      # - user: Current user data with profiles
      # - current_profile: Currently active profile (if selected)
      def login
        user = authenticate_user_from_params

        if user
          if @inactive_account_type.present?
            @current_user = user
            handle_inactive_account(@inactive_account_type)
            return
          end

          # Create OAuth tokens via Doorkeeper
          token_response = create_oauth_token(user)

          if token_response
            render json: {
              message: "Login successful",
              access_token: token_response.token,
              refresh_token: token_response.refresh_token,
              token_type: "Bearer",
              expires_in: token_response.expires_in,
              created_at: token_response.created_at,
              user: serialize_user(user, token_response),
              current_profile: serialize_current_profile(user, token_response)
            }, status: :ok
          else
            render json: {
              error: "token_creation_failed",
              message: "Failed to create authentication token"
            }, status: :internal_server_error
          end
        else
          render json: create_errors_json("The email/username or password you entered is incorrect", type: "invalid_credentials"), status: :unauthorized
        end
      end

      # POST /api/v1/auth/refresh
      # Refresh an expired access token
      #
      # Params:
      # - refresh_token: string (required)
      #
      # Response:
      # - access_token: New access token
      # - refresh_token: New refresh token
      # - expires_in: New TTL
      def refresh
        refresh_token_param = params[:refresh_token]

        unless refresh_token_param.present?
          render json: {
            error: "missing_refresh_token",
            message: "Refresh token is required"
          }, status: :unprocessable_entity
          return
        end
        begin
          # Find the refresh token (the refresh token is a column on the access tokens table)
          token = Doorkeeper::AccessToken.find_by(refresh_token: refresh_token_param)

          if token && !token.revoked? && !token.expired?
            # Resolve resource owner (user) from token
            owner = User.find_by(id: token.resource_owner_id)
            unless owner
              Rails.logger.error "[API Auth#refresh] Token owner not found for token id=#{token.id} owner_id=#{token.resource_owner_id}"
              render json: { error: "invalid_refresh_token", message: "Refresh token is invalid or expired" }, status: :unauthorized and return
            end

            # Create new tokens
            new_token = create_oauth_token(owner)

            if new_token
              # Copy profile cache from old token to new token so client keeps selected profile after refresh
              begin
                old_profile_id = Rails.cache.read("profile_#{token.token}")
                if old_profile_id.present?
                  Rails.cache.write("profile_#{new_token.token}", old_profile_id, expires_in: 24.hours)
                end
              rescue => e
                Rails.logger.error "[API Auth#refresh] Failed to copy profile cache: #{e.class} - #{e.message}"
              end

              # Revoke old token
              token.revoke

              render json: {
                access_token: new_token.token,
                refresh_token: new_token.refresh_token,
                token_type: "Bearer",
                expires_in: new_token.expires_in,
                created_at: new_token.created_at
              }, status: :ok
            else
              render json: {
                error: "token_creation_failed",
                message: "Failed to create new token"
              }, status: :internal_server_error
            end
          else
            render json: {
              error: "invalid_refresh_token",
              message: "Refresh token is invalid or expired"
            }, status: :unauthorized
          end
        rescue => e
          Rails.logger.error "[API Auth#refresh] Exception: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
          render json: { error: 'internal_error', message: 'Internal server error' }, status: :internal_server_error
        end
      end

      # GET /api/v1/auth/me
      # Get current authenticated user with profiles
      # Requires: Bearer token in Authorization header
      #
      # Response:
      # - user: Complete user data with all profiles
      # - current_profile: Currently selected profile (if any)
      # - needs_profile_selection: true if no profile is selected
      def me
        user = get_user_from_token

        render json: {
          user: serialize_user(user, doorkeeper_token),
          current_profile: serialize_current_profile(user, doorkeeper_token),
          needs_profile_selection: current_profile_for_token(doorkeeper_token).nil?
        }, status: :ok
      end

      # GET /api/v1/auth/profile-status
      # Check if current user has selected a profile
      # Requires: Bearer token in Authorization header
      #
      # Response:
      # - has_profile_selected: boolean
      # - current_profile: Profile data if selected
      # - profiles: List of available profiles
      # - needs_profile_selection: boolean helper
      def profile_status
        user = get_user_from_token
        profile = current_profile_for_token(doorkeeper_token)

        render json: {
          authenticated: true,
          has_profile_selected: profile.present?,
          current_profile: profile ? serialize_profile(profile) : nil,
          profiles: user.profiles.map { |p| serialize_profile(p) },
          profiles_count: user.profiles.count,
          needs_profile_selection: profile.nil?
        }, status: :ok
      end

      # POST /api/v1/auth/select-profile
      # Select an active profile for the current user
      # Requires: Bearer token in Authorization header
      #
      # Params:
      # - profile_id: UUID of the profile to select (required)
      #
      # Response:
      # - current_profile: The newly selected profile
      # - message: Success message
      def select_profile
        user = get_user_from_token
        profile_id = params[:profile_id]

        unless profile_id.present?
          render json: {
            error: "missing_profile_id",
            message: "Profile ID is required"
          }, status: :unprocessable_entity
          return
        end

        # Find profile that belongs to user
        profile = user.profiles.find_by(id: profile_id)

        unless profile
          render json: {
            error: "profile_not_found",
            message: "Profile not found or doesn't belong to you"
          }, status: :not_found
          return
        end

        # Store profile ID in cache linked to the token
        set_current_profile_id(doorkeeper_token, profile.id)

        render json: {
          message: "Profile selected successfully",
          current_profile: serialize_profile(profile),
          user: serialize_user(user, doorkeeper_token)
        }, status: :ok
      end

      # POST /api/v1/auth/deassign-profile
      # Deselect the current profile
      # Requires: Bearer token in Authorization header
      def deassign_profile
        set_current_profile_id(doorkeeper_token, nil)

        render json: {
          message: "Profile deselected successfully",
          current_profile: nil,
          needs_profile_selection: true
        }, status: :ok
      end

      # DELETE /api/v1/auth/logout
      # Revoke the current access token
      # Requires: Bearer token in Authorization header
      def logout
        token = doorkeeper_token

        if token
          # Clear profile cache
          clear_profile_cache(token)
          # Revoke the token
          token.revoke

          render json: {
            message: "Logout successful"
          }, status: :ok
        else
          render json: {
            message: "No active session"
          }, status: :ok
        end
      end

      private

      # Authenticate user from login params
      def authenticate_user_from_params
        login_param = params[:email] || params[:username] || params.dig(:auth, :email) || params.dig(:auth, :username)
        password = params[:password] || params.dig(:auth, :password)

        return nil unless login_param.present? && password.present?

        # Try email first, then username
        user = User.find_by(email: login_param.downcase)
        user ||= User.find_by(username: login_param)

        return nil unless user&.valid_password?(password)

        unless user.active_for_authentication?
          @inactive_account_type = user.deactivated? ? :deactivated : :suspended
          return user
        end

        user
      end

      # Create OAuth access token for user
      def create_oauth_token(user)
        # Create token directly (bypasses authorization flow)
        Doorkeeper::AccessToken.create!(
          resource_owner_id: user.id,
          application: Doorkeeper::Application.first || create_default_application,
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: true
        )
      rescue => e
        Rails.logger.error "[API Auth] Failed to create token: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
        nil
      end

      # Create default application if none exists
      def create_default_application
        Doorkeeper::Application.create!(
          name: "Default API Client",
          uid: SecureRandom.hex(16),
          secret: SecureRandom.hex(32),
          redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
          scopes: "read write"
        )
      end

      # Get user from Doorkeeper token
      def get_user_from_token
        return @api_current_user if defined?(@api_current_user)

        @api_current_user = User.find_by(id: doorkeeper_token.resource_owner_id)
      end

      # Get current profile for the token
      def current_profile_for_token(token)
        profile_id = get_current_profile_id(token)
        return nil unless profile_id.present?

        user = get_user_from_token
        user&.profiles&.find_by(id: profile_id)
      end

      # Get stored profile ID for token
      def get_current_profile_id(token)
        Rails.cache.read("profile_#{token.token}")
      end

      # Set profile ID for token
      def set_current_profile_id(token, profile_id)
        Rails.cache.write(
          "profile_#{token.token}",
          profile_id,
          expires_in: 24.hours
        )
      end

      # Clear profile cache
      def clear_profile_cache(token)
        Rails.cache.delete("profile_#{token.token}")
      end

      # Serialize helpers
      def serialize_user(user, token)
        CurrentUserSerializer.new(user, {
          include_profiles: true,
          current_profile_id: get_current_profile_id(token)
        }).as_json
      end

      def serialize_current_profile(user, token)
        profile = current_profile_for_token(token)
        profile ? serialize_profile(profile) : nil
      end

      def serialize_profile(profile)
        {
          id: profile.id,
          name: profile.name,
          profile_type: profile.profile_type,
          avatar_id: profile.avatar_id,
          created_at: profile.created_at,
          updated_at: profile.updated_at
        }
      end

      # Authenticate via Doorkeeper token only (no Devise fallback)
      def authenticate_api_token!
        doorkeeper_authorize!
      rescue Doorkeeper::Errors::DoorkeeperError => e
        render json: {
          error: "unauthorized",
          message: "Invalid or expired token"
        }, status: :unauthorized
      end
    end
  end
end
