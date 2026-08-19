# frozen_string_literal: true

module Live
  class EventsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :attend, :unattend]

    def index
      active = Live::Event.active.public_events
                           .includes(:content, :organizer, :watch_party_session)

      upcoming = Live::Event.upcoming.public_events
                            .includes(:content, :attendees)

      render json: {
        active: active.map { |e| serialize_event(e) },
        upcoming: upcoming.map { |e| serialize_event(e, include_attendees: true) }
      }
    end

    def show
      event = Live::Event.find(params[:id])

      render json: serialize_event(event, detailed: true)
    end

    def create
      if event_scheduling_restricted? && !current_user.is_admin?
        return render json: { error: "Only admins can schedule events" }, status: :forbidden
      end

      event = Live::Event.new(event_params)
      event.organizer = current_user

      if event.save
        if defined?(MessageBus)
          MessageBus.publish("/live/status", {
            type: "event_created",
            event_id: event.id,
            title: event.title || event.content.title
          })
        end

        render json: serialize_event(event), status: :created
      else
        render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def attend
      event = Live::Event.find(params[:id])

      unless event.can_accept_attendees?
        return render json: { error: "Event is not accepting attendees" }, status: :unprocessable_entity
      end

      attendee = event.attendees.find_or_create_by!(profile: current_profile)
      count = event.attendee_count

      if defined?(MessageBus)
        MessageBus.publish("/live/event/#{event.id}", {
          type: "attendee_count_changed",
          count: count
        })
      end

      render json: { attending: true, count: count }
    end

    def unattend
      event = Live::Event.find(params[:id])
      event.attendees.where(profile: current_profile).destroy_all
      count = event.attendee_count

      if defined?(MessageBus)
        MessageBus.publish("/live/event/#{event.id}", {
          type: "attendee_count_changed",
          count: count
        })
      end

      render json: { attending: false, count: count }
    end

    private

    def event_params
      params.permit(:content_id, :title, :description, :starts_at, :max_participants, :is_public)
    end

    def event_scheduling_restricted?
      return false unless defined?(SiteSetting)

      SiteSetting.cinelar_live_event_scheduling == "admins_only"
    end

    def serialize_event(event, detailed: false, include_attendees: false)
      data = {
        id: event.id,
        title: event.title || event.content&.title,
        description: event.description,
        content: event.content ? {
          id: event.content.id,
          title: event.content.title,
          poster: event.content.cover,
          year: event.content.year
        } : nil,
        status: event.status,
        starts_at: event.starts_at&.iso8601,
        attendee_count: event.attendee_count,
        is_attending: current_profile ? event.attendees.exists?(profile_id: current_profile.id) : false,
        session_id: event.watch_party_session&.id
      }

      if detailed
        data[:organizer] = {
          id: event.organizer_id,
          username: event.organizer.username
        }
        data[:estimated_end_at] = event.estimated_end_at&.iso8601

        if event.live? && event.content
          sources = event.content.video_sources.reject { |vs| vs.trailer == true }
          data[:sources] = sources.map { |vs| { id: vs.id, url: vs.url, quality: vs.quality } }
        end
      end

      data
    end
  end
end
