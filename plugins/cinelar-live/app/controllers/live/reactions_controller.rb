# frozen_string_literal: true

module Live
  class ReactionsController < ApplicationController
    before_action :authenticate_user!
    before_action :find_event

    VALID_EMOJIS = %w[❤️ 😂 👍 🔥 😮 💯].freeze

    def create
      emoji = params[:emoji]

      unless VALID_EMOJIS.include?(emoji)
        return render json: { error: "Invalid emoji" }, status: :unprocessable_entity
      end

      unless @event.live?
        return render json: { error: "Event is not live" }, status: :unprocessable_entity
      end

      broadcast_reaction(emoji)
      render json: { success: true }
    end

    private

    def find_event
      @event = Live::Event.find(params[:event_id])
    end

    def broadcast_reaction(emoji)
      return unless defined?(MessageBus)

      MessageBus.publish("/live/event/#{@event.id}", {
        type: "reaction",
        emoji: emoji,
        user_id: current_profile.user_id,
        username: current_profile.user.username,
        timestamp: Time.current.iso8601
      })
    end
  end
end
