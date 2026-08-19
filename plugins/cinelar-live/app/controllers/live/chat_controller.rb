# frozen_string_literal: true

module Live
  class ChatController < ApplicationController
    before_action :authenticate_user!
    before_action :find_event

    MESSAGES_PER_PAGE = 100

    def index
      messages = @event.chat_messages
                       .visible
                       .includes(profile: :user)
                       .order(created_at: :asc)
                       .last(MESSAGES_PER_PAGE)

      render json: {
        messages: messages.map { |m| serialize_message(m) },
        event_id: @event.id
      }
    end

    def create
      unless @event.live?
        return render json: { error: "Event is not live" }, status: :unprocessable_entity
      end

      unless @event.attendees.exists?(profile_id: current_profile&.id) ||
             @event.organizer_id == current_profile&.user_id
        return render json: { error: "Must be attending to chat" }, status: :forbidden
      end

      message = @event.chat_messages.build(
        profile: current_profile,
        message_type: "user",
        body: params[:body]&.strip
      )

      if message.save
        broadcast_message(message)
        render json: serialize_message(message), status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      message = @event.chat_messages.find(params[:id])

      unless organizer_or_message_owner?(message)
        return render json: { error: "Not authorized" }, status: :forbidden
      end

      message.soft_delete!
      broadcast_deletion(message)
      render json: { success: true }
    end

    private

    def find_event
      @event = Live::Event.find(params[:event_id])
    end

    def organizer_or_message_owner?(message)
      @event.organizer_id == current_profile&.user_id ||
        message.profile_id == current_profile&.id
    end

    def broadcast_message(message)
      return unless defined?(MessageBus)

      MessageBus.publish("/live/event/#{@event.id}", {
        type: "chat_message",
        id: message.id,
        profile_id: message.profile_id,
        username: message.profile.user.username,
        avatar: avatar_url(message.profile),
        body: message.body,
        message_type: message.message_type,
        timestamp: message.created_at.iso8601
      })
    end

    def broadcast_deletion(message)
      return unless defined?(MessageBus)

      MessageBus.publish("/live/event/#{@event.id}", {
        type: "message_deleted",
        id: message.id
      })
    end

    def avatar_url(profile)
        avatar_id = profile.avatar_id || "coolCat"
      "/assets/default/avatars/#{avatar_id}.png"
    end

    def serialize_message(message)
      {
        id: message.id,
        profile_id: message.profile_id,
        username: message.profile.user.username,
        avatar: avatar_url(message.profile),
        body: message.body,
        message_type: message.message_type,
        deleted: message.deleted,
        timestamp: message.created_at.iso8601
      }
    end
  end
end
