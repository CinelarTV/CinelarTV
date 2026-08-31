# frozen_string_literal: true

# app/serializers/content_serializer.rb
class ContentSerializer < ApplicationSerializer
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper

  attributes :id,
             :title,
             :description,
             :content_type,
             :year,
             :created_at,
             :updated_at,
             :available,
             :premium,
             :tmdb_id,
             :scheduled_launch_at

  # Content rating and descriptors
  attribute :content_rating
  attribute :content_descriptors
  attribute :advisory_text

  # New structured images
  attribute :images

  # Legacy backward-compatible fields (deprecated, will be removed in v2)
  attribute :poster
  attribute :backdrop
  attribute :cover
  attribute :banner
  attribute :banner_resized
  attribute :cover_resized

  attribute :seasons, if: :include_seasons?
  attribute :liked, key: "liked"
  attribute :disliked, key: "disliked"
  attribute :similar_items, key: "related_content"
  attribute :continue_watching, key: "continue_watching"
  attribute :categories
  attribute :cast_members
  attribute :trailer_video_sources

  def images
    {
      poster: object.image_variants_for("poster"),
      backdrop: object.image_variants_for("backdrop"),
      logo: object.image_variants_for("logo")
    }
  end

  # Legacy accessors (backward compat)
  def poster
    object.image_url_for("poster")
  end

  def backdrop
    object.image_url_for("backdrop")
  end

  def logo
    object.image_url_for("logo")
  end

  def cover
    object.image_url_for("poster")
  end

  def banner
    object.image_url_for("backdrop")
  end

  def banner_resized
    object.image_url_for("backdrop", variant: "medium")
  end

  def cover_resized
    object.image_url_for("poster", variant: "medium")
  end

  def content_rating
    locale = @options[:locale] || I18n.locale
    object.content_rating&.as_json_with_locale(locale: locale)
  end

  def content_descriptors
    locale = @options[:locale] || I18n.locale
    object.effective_descriptors(locale: locale).map { |d| d.as_json_with_locale(locale: locale) }
  end

  def advisory_text
    locale = @options[:locale] || I18n.locale
    object.advisory_text(locale: locale)
  end

  def include_seasons?
    object.content_type == Content.content_types["TVSHOW"]
  end

  def seasons
    return unless object.content_type == Content.content_types["TVSHOW"]

    continue_watching_by_episode = fetch_episodes_continue_watching

    object.seasons
          .sort_by(&:position)
          .map do |season|
      {
        id: season.id,
        title: season.title,
        description: season.description,
        episodes: season.episodes.sort_by(&:position).map do |episode|
          episode_attributes(episode, continue_watching_by_episode[episode.id])
        end,
      }
    end
  end

  def liked
    profile = @options[:current_profile]
    return false unless profile

    CinelarTV.cache.fetch("profile_liked_ids/#{profile.id}", expires_in: 30.minutes) do
      profile.liked_contents.pluck(:id)
    end.include?(object.id)
  end

  def disliked
    profile = @options[:current_profile]
    return false unless profile

    CinelarTV.cache.fetch("profile_disliked_ids/#{profile.id}", expires_in: 30.minutes) do
      profile.disliked_contents.pluck(:id)
    end.include?(object.id)
  end

  def categories
    object.categories.map { |category| { id: category.id, name: category.name } }
  end

  def cast_members
    object.cast_members.includes(:person).ordered.map do |cm|
      {
        id: cm.id,
        character_name: cm.character_name,
        order: cm.order,
        name: cm.person&.name,
        profile_path: cm.person&.profile_path
      }
    end
  end

  def trailer_video_sources
    object.trailer_video_sources.map do |vs|
      {
        quality: vs.quality,
        url: vs.url,
      }
    end
  end

  private

  def fetch_episodes_continue_watching
    profile = @options[:current_profile]
    return {} unless profile

    episode_ids = object.seasons.flat_map { |season| season.episodes.map(&:id) }

    ContinueWatching
      .where(profile: profile, episode_id: episode_ids)
      .index_by(&:episode_id)
  end

  def episode_attributes(episode, continue_watching_data = nil)
    locale = @options[:locale] || I18n.locale
    thumbnail_url = episode.image_url_for("episode_thumbnail") || object.image_url_for("backdrop")
    thumbnail_medium = episode.image_url_for("episode_thumbnail", variant: "medium") ||
                       object.image_url_for("backdrop", variant: "medium")

    attributes = episode.as_json(only: %i[id title description position premium])
    attributes[:thumbnail] = thumbnail_url
    attributes[:thumbnail_resized] = thumbnail_medium
    attributes[:content_rating] = episode.effective_content_rating&.as_json_with_locale(locale: locale)
    attributes[:content_descriptors] = episode.effective_descriptors(locale: locale).map { |d| d.as_json_with_locale(locale: locale) }
    attributes[:advisory_text] = episode.advisory_text(locale: locale)
    attributes[:images] = {
      episode_thumbnail: episode.image_variants_for("episode_thumbnail")
    }

    if continue_watching_data
      cw_data = continue_watching_data.as_json(only: %i[progress duration])

      redis_data = CinelarTV.cache.read("progress/#{continue_watching_data.profile_id}/#{continue_watching_data.content_id}/#{episode.id}")
      if redis_data
        cw_data["progress"] = redis_data[:progress] if redis_data[:progress]
        cw_data["duration"] = redis_data[:duration] if redis_data[:duration]
      end

      attributes[:continue_watching] = cw_data
    end

    attributes
  end

  def similar_items
    related = object.similar_items
    related_ids = related.map(&:id)

    all_variants = ImageVariant.where(imageable_type: "Content", imageable_id: related_ids).to_a
    variants_by_content = all_variants.group_by(&:imageable_id)

    related.each do |r|
      r.association(:image_variants).target = variants_by_content[r.id] || []
    end

    related.map { |related| similar_items_attributes(related) }
  end

  def similar_items_attributes(related)
    {
      id: related.id,
      title: related.title,
      description: related.description,
      banner: related.image_url_for("backdrop"),
      cover: related.image_url_for("poster"),
      banner_resized: related.image_url_for("backdrop", variant: "medium"),
      cover_resized: related.image_url_for("poster", variant: "medium"),
      images: {
        poster: related.image_variants_for("poster"),
        backdrop: related.image_variants_for("backdrop"),
        logo: related.image_variants_for("logo")
      }
    }
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
                              %i[episode_id progress duration finished]
                            elsif object.content_type == Content.content_types["MOVIE"]
                              %i[progress duration finished]
                            else
                              []
                            end

    return unless attributes_to_include.any?

    data = continue_watching.as_json(only: attributes_to_include)

    episode_key = continue_watching.episode_id.presence || "movie"
    redis_data = CinelarTV.cache.read("progress/#{continue_watching.profile_id}/#{continue_watching.content_id}/#{episode_key}")

    if redis_data
      data["progress"] = redis_data[:progress] if redis_data[:progress]
      data["duration"] = redis_data[:duration] if redis_data[:duration]
    end

    data
  end
end
