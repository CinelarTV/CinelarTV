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

  # Agrega otras atributos según sea necesario

  def include_seasons?
    object.content_type == Content.types["TVSHOW"]
  end

  def seasons
    return unless object.content_type == Content.types["TVSHOW"]

    object.seasons
          .sort_by(&:position) # Ordenar las temporadas por posición
          .map do |season|
      {
        id: season.id,
        title: season.title,
        description: season.description,
        episodes: season.episodes.map { |episode| episode_attributes(episode) },
      }
    end
  end

  def liked
    @options[:current_profile].liked_contents.include?(object)
  end

  private

  def episode_attributes(episode)
    attributes = episode.as_json(only: %i[id title description position thumbnail position])
    attributes[:thumbnail] = episode.thumbnail || object.banner
    attributes # Asegúrate de devolver el hash attributes
  end

  def similar_items
    object.similar_items.map { |related| similar_items_attributes(related) }
  end

  def similar_items_attributes(related)
    attibutes = related.as_json(only: %i[id title description banner cover])
  end

  def continue_watching
    cw = ContinueWatching
         .where(profile: @options[:current_profile], content: object)
         .order(updated_at: :desc)
         .first

    return unless cw.present?

    if object.content_type == Content.types["TVSHOW"] && cw.episode_id.present?
      continue_watching_attributes(cw)
    elsif object.content_type == Content.types["MOVIE"]
      continue_watching_attributes(cw)
    end
  end

  def continue_watching_attributes(continue_watching)
    attributes_to_include = if object.content_type == Content.types[:TVSHOW]
                              %i[episode_id progress duration]
                            elsif object.content_type == Content.types[:MOVIE]
                              %i[progress duration]
                            else
                              []
                            end

    attributes = continue_watching.as_json(only: attributes_to_include) unless attributes_to_include.empty?
  end
end
