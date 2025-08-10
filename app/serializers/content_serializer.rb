# frozen_string_literal: true

# app/serializers/content_serializer.rb
class ContentSerializer < ApplicationSerializer
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper

  attributes :id,
             :title,
             :description,
             :banner,
             :cover,
             :content_type,
             :year,
             :created_at,
             :updated_at,
             :trailer_url,
             :available

  attribute :seasons, if: :include_seasons?
  attribute :liked, key: "liked"
  attribute :similar_items, key: "related_content"
  attribute :continue_watching, key: "continue_watching"

  def include_seasons?
    object.content_type == Content.content_types["TVSHOW"]
  end

  def seasons
    return unless object.content_type == Content.content_types["TVSHOW"]

    # Optimización: una sola consulta para todos los continue_watching de los episodios
    continue_watching_by_episode = fetch_episodes_continue_watching

    object.seasons
          .sort_by(&:position)
          .map do |season|
      {
        id: season.id,
        title: season.title,
        description: season.description,
        episodes: season.episodes.map { |episode| 
          episode_attributes(episode, continue_watching_by_episode[episode.id]) 
        },
      }
    end
  end

  def liked
    profile = @options[:current_profile]
    return false unless profile&.respond_to?(:liked_contents)

    profile.liked_contents.include?(object)
  end

  private

  def fetch_episodes_continue_watching
    profile = @options[:current_profile]
    return {} unless profile

    # Una sola consulta para obtener todos los continue_watching de los episodios del contenido
    episode_ids = object.seasons.flat_map { |season| season.episodes.pluck(:id) }
    
    ContinueWatching
      .where(profile: profile, episode_id: episode_ids)
      .index_by(&:episode_id)
  end

  def episode_attributes(episode, continue_watching_data = nil)
    attributes = episode.as_json(only: %i[id title description position thumbnail])
    attributes[:thumbnail] = episode.thumbnail.presence || object.banner
    
    # Agregar continue_watching si existe
    if continue_watching_data
      attributes[:continue_watching] = continue_watching_data.as_json(only: %i[progress duration])
    end
    
    attributes
  end

  def similar_items
    object.similar_items.map { |related| similar_items_attributes(related) }
  end

  def similar_items_attributes(related)
    related.as_json(only: %i[id title description banner cover])
  end

  def continue_watching
    profile = @options[:current_profile]
    return unless profile

    cw = ContinueWatching
         .where(profile: profile, content: object)
         .order(updated_at: :desc)
         .first

    return unless cw.present?

    if object.content_type == Content.content_types["TVSHOW"] && cw.episode_id.present?
      continue_watching_attributes(cw)
    elsif object.content_type == Content.content_types["MOVIE"]
      continue_watching_attributes(cw)
    end
  end

  def continue_watching_attributes(continue_watching)
    attributes_to_include = if object.content_type == Content.content_types["TVSHOW"]
                              %i[episode_id progress duration]
                            elsif object.content_type == Content.content_types["MOVIE"]
                              %i[progress duration]
                            else
                              []
                            end

    return unless attributes_to_include.any?

    continue_watching.as_json(only: attributes_to_include)
  end
end