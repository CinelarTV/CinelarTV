# frozen_string_literal: true

class StreamSessionsController < ApplicationController
  before_action :authenticate_user!

  def ping
    session_id = stream_session_id_param
    return render json: { error: "MISSING_SESSION_ID" }, status: :bad_request if session_id.blank?

    session_data = StreamSessionManager.ping_session(session_id, current_user)
    if session_data
      render json: { success: true, session: session_data }
    else
      render json: { error: "STREAM_SESSION_NOT_FOUND" }, status: :not_found
    end
  end

  def end_stream
    session_id = stream_session_id_param
    return render json: { error: "MISSING_SESSION_ID" }, status: :bad_request if session_id.blank?

    if StreamSessionManager.end_session(session_id, current_user)
      head :no_content
    else
      render json: { error: "STREAM_SESSION_NOT_FOUND" }, status: :not_found
    end
  end

  def kill
    target_session_id = params[:target_session_id].presence || stream_session_id_param
    return render json: { error: "MISSING_SESSION_ID" }, status: :bad_request if target_session_id.blank?

    case StreamSessionManager.kill_session(current_user, target_session_id)
    when true
      head :no_content
    when :disabled
      render json: { error: "STREAM_FORCE_KILL_DISABLED" }, status: :forbidden
    when :forbidden
      render json: { error: "STREAM_SESSION_FORBIDDEN" }, status: :forbidden
    else
      render json: { error: "STREAM_SESSION_NOT_FOUND" }, status: :not_found
    end
  end

  def index
    sessions = StreamSessionManager.list_sessions(current_user, current_profile&.id)
    render json: { sessions: sessions }
  end

  private

  def stream_session_id_param
    params[:session_id].presence || params[:deviceSessionToken].presence
  end
end
