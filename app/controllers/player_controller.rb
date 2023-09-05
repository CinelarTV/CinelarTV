# frozen_string_literal: true

class PlayerController < ApplicationController
  before_action :authenticate_user!
  before_action :find_content, only: :watch

  def watch
    if @content
      case @content.content_type
      when "TVSHOW"
        if params[:episode_id]
          @episode = Episode.find_by(id: params[:episode_id])
        else
          @season = @content.seasons.first
          @episode = @season.episodes.first if @season
        end
      when "MOVIE"
        # No se requiere ningún procesamiento adicional para películas.
      end

      profile = Profile.find_by(id: session[:current_profile_id])

      # Si profile existe, encuentra o crea un registro ContinueWatching
      if profile && @content
        continue_watching = ContinueWatching.find_or_create_by(
          profile_id: profile.id,
          content_id: @content.id,
          episode_id: @episode&.id,
        )
      end

      respond_to do |format|
        format.html
        format.json do
          if @content
            data = {
              content: @content.as_json(except: %i[created_at updated_at]),
              episode: @episode&.as_json(except: %i[created_at updated_at]),
              season: @season&.as_json(except: %i[created_at updated_at]),
              continue_watching: continue_watching&.as_json(except: %i[created_at updated_at profile_id episode_id content_id id]),
            }
            render json: { data: data }
          else
            render json: {
                     errors: ["Content not found"],
                     error_type: "content_not_found",
                   }
          end
        end
      end
    end
  end

  def update_current_progress
    profile_id = Profile.find_by(id: session[:current_profile_id])&.id
    @content = Content.find_by(id: params[:id])

    if @content
      if @content.content_type == "TVSHOW"
        # Si es una serie (TVSHOW), también necesitamos el episodio correspondiente
        episode = Episode.find_by(id: params[:episode_id])

        if episode
          # Encuentra o crea un registro ContinueWatching para el perfil, contenido y episodio
          continue_watching = ContinueWatching.find_or_create_by(
            profile_id: profile_id,
            content_id: @content.id,
            episode_id: episode.id,
          )

          Rails.logger.info "Continue Watching: #{continue_watching.inspect}"

          # Actualiza el progreso y la duración según los parámetros que recibas
          progress = params[:progress].to_d
          duration = params[:duration].to_d

          # Actualiza el registro ContinueWatching
          continue_watching.update(
            progress: progress,
            duration: duration,
            last_watched_at: Time.now,
          )

          continue_watching.save

          # Puedes responder con un mensaje de éxito
          render json: { message: "Progreso actualizado exitosamente." }
        else
          # Maneja el caso en el que no se encuentra el episodio
          render json: { message: "Episodio no encontrado." }, status: :not_found
        end
      elsif @content.content_type == "MOVIE"
        # Si es una película, no necesitas un episodio
        # Encuentra o crea un registro ContinueWatching para el perfil y contenido
        continue_watching = ContinueWatching.find_or_create_by(
          profile_id: profile_id,
          content_id: @content.id,
        )

        # Actualiza el progreso y la duración según los parámetros que recibas
        progress = params[:progress].to_d
        duration = params[:duration].to_d

        # Actualiza el registro ContinueWatching
        continue_watching.update(
          progress: progress,
          duration: duration,
          last_watched_at: Time.now,
        )

        # Puedes responder con un mensaje de éxito
        render json: { message: "Progreso actualizado exitosamente." }
      else
        # Maneja el caso en el que el tipo de contenido no es válido
        render json: { message: "Tipo de contenido no válido." }, status: :unprocessable_entity
      end
    else
      # Maneja el caso en el que no se encuentra el contenido
      render json: { message: "Contenido no encontrado." }, status: :not_found
    end
  end

  private

  def find_content
    @content = Content.find_by(id: params[:id])
  end
end
