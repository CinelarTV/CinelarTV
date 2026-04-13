# frozen_string_literal: true

module WatchParty
  class SessionsController < ApplicationController
    before_action :require_login
    before_action :find_session, only: [:join, :leave, :sync, :chat]

    private

    def require_login
      unless respond_to?(:current_user) && current_user
        render json: { error: "Authentication required" }, status: :unauthorized
      end
    end

    def find_session
      # Placeholder for before_action
    end

    public

    def create
      content_id = params[:content_id]
      raise ActionController::BadRequest, "content_id is required" unless content_id.present?

      session = WatchParty::Session.create!(
        content_id: content_id,
        host_id: current_user.id,
        user_id: current_user.id,
        started_at: Time.now
      )

      WatchParty::SessionUser.create!(
        watch_party_session_id: session.id,
        user_id: current_user.id,
        is_host: true,
        joined_at: Time.now
      )

      render json: {
        session_id: session.id,
        content_id: session.content_id,
        host_id: session.host_id,
        users: format_users(session.session_users),
        is_host: true
      }, status: :created
    end

    def join
      session_id = params[:session_id]
      session = WatchParty::Session.find_by!(id: session_id)

      # Don't allow joining if session is full or ended
      if session.session_users.count >= 10
        return render json: { error: "Session is full" }, status: :unprocessable_entity
      end

      # Check if user already in session
      existing_user = WatchParty::SessionUser.find_by(
        watch_party_session_id: session.id,
        user_id: current_user.id
      )

      unless existing_user
        WatchParty::SessionUser.create!(
          watch_party_session_id: session.id,
          user_id: current_user.id,
          is_host: false,
          joined_at: Time.now
        )
      end

      # Notify others via MessageBus
      if defined?(MessageBus)
        avatar_id = current_user.profiles.first&.avatar_id || "coolCat"
        user_avatar = "/assets/default/avatars/#{avatar_id}.png"
        MessageBus.publish("/watchparty/#{session.id}", {
        type: "user_joined",
        user_id: current_user.id,
        user_name: current_user.username,
        user_avatar: user_avatar,
        user: {
          id: current_user.id,
          name: current_user.username,
          avatar: user_avatar,
          is_host: false,
          joined_at: Time.now
        }
      })
      end

      render json: {
        session_id: session.id,
        users: format_users(session.session_users),
        is_host: session.host_id == current_user.id
      }
    end

    def leave
      session = WatchParty::Session.find_by!(id: params[:session_id])
      session_user = WatchParty::SessionUser.find_by(
        watch_party_session_id: session.id,
        user_id: current_user.id
      )

      if session_user
        is_host = session_user.is_host
        session_user.destroy

        # If host left, end session or transfer
        if is_host && session.session_users.any?
          # Transfer host to first user
          new_host = session.session_users.first
          session.update(host_id: new_host.user_id)
          WatchParty::SessionUser.find_by(
            watch_party_session_id: session.id,
            user_id: new_host.user_id
          )&.update(is_host: true)

          if defined?(MessageBus)
            MessageBus.publish("/watchparty/#{session.id}", {
              type: "host_transferred",
              new_host_id: new_host.user_id,
              new_host_name: new_host.user.username
            })
          end
        end

        # Notify others
        if defined?(MessageBus)
          MessageBus.publish("/watchparty/#{session.id}", {
            type: "user_left",
            user_id: current_user.id,
            user_name: current_user.username
          })
        end
      end

      render json: { success: true }
    end

    def sync
      session = WatchParty::Session.find_by!(id: params[:session_id])
      current_time = params[:current_time]
      is_playing = params[:is_playing]

      # Only host can sync
      unless session.host_id == current_user.id
        return render json: { error: "Only host can sync" }, status: :forbidden
      end

      # Update session state
      session.update(
        playback_current_time: current_time,
        is_playing: is_playing,
        last_sync_at: Time.now
      )

      # Broadcast to all users
      if defined?(MessageBus)
        MessageBus.publish("/watchparty/#{session.id}", {
          type: "playback_sync",
          current_time: current_time,
          is_playing: is_playing,
          user_id: current_user.id
        })
      end

      render json: { success: true }
    end

    def chat
      session = WatchParty::Session.find_by!(id: params[:session_id])
      text = params[:text]&.strip

      return render json: { error: "Message cannot be empty" }, status: :unprocessable_entity if text.blank?

      # Broadcast message to all users in session
      if defined?(MessageBus)
        avatar_id = current_user.profiles.first&.avatar_id || "coolCat"
        user_avatar = "/assets/default/avatars/#{avatar_id}.png"
        MessageBus.publish("/watchparty/#{session.id}", {
          type: "chat_message",
          user_id: current_user.id,
          user_name: current_user.username,
          user_avatar: user_avatar,
          text: text,
          timestamp: Time.now
        })
      end

      render json: { success: true }
    end

    def status
      session = WatchParty::Session.find_by!(id: params[:session_id])

      render json: {
        session_id: session.id,
        users: format_users(session.session_users),
        current_time: session.playback_current_time,
        is_playing: session.is_playing,
        is_host: session.host_id == current_user.id
      }
    end

    private

    def find_session
      # Used by before_action for specific actions
    end

    def format_users(users)
      users.includes(:user).map do |session_user|
        avatar_id = session_user.user.profiles.first&.avatar_id || "coolCat"
        {
          id: session_user.user.id,
          name: session_user.user.username,
          avatar: "/assets/default/avatars/#{avatar_id}.png",
          is_host: session_user.is_host,
          joined_at: session_user.created_at
        }
      end
    end
  end
end
