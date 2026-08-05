# frozen_string_literal: true

# app/controllers/home_controller.rb
class HomeController < ApplicationController
  include HomeHelper

  def homepage
    @title = nil
    @description = SiteSetting.site_description.presence
    @banner = SiteSetting.site_logo

    respond_to do |format|
      format.html
      format.json do
        # ETag compuesto: cambia cuando el catálogo o el perfil del usuario cambian.
        # private: la respuesta incluye datos personalizados (continue_watching, liked).
        latest_updated = Content.maximum(:updated_at) || Time.current
        profile_version = current_profile&.updated_at.to_i
        composite_etag = Digest::MD5.hexdigest("#{latest_updated.to_i}-#{profile_version}")

        if stale?(last_modified: latest_updated, etag: composite_etag, public: false)
          render json: homepage_data
        end
      end
    end
  end

  def browse
    category_id = params[:category_id]
    content_type = params[:content_type]
    sort = params[:sort] || "trending"

    categories = Category
                 .joins(:contents)
                 .where(contents: { available: true })
                 .group("categories.id")
                 .having("COUNT(contents.id) >= 1")
                 .order(:name)

    content = Content.includes(:categories, :content_analytic)

    content = content.where(content_type: content_type) if content_type.present?
    content = content.joins(:content_categories).where(content_categories: { category_id: category_id }) if category_id.present?

    content = case sort
              when "newest"
                content.order(created_at: :desc)
              when "most_liked"
                content.left_joins(:liking_profiles)
                       .group("contents.id")
                       .order(Arel.sql("COUNT(likes.profile_id) DESC"))
              else
                content.left_joins(:content_analytic)
                       .order(Arel.sql("COALESCE(content_analytics.total_views, 0) DESC"))
              end

    raw_variants = params[:img_variants]
    allowed = if raw_variants.present?
                raw_variants.split(",").map(&:strip).presence
              end
    allowed ||= %w[original medium large]

    contents_data = content.limit(50).map do |c|
      { id: c.id, title: c.title, description: c.description,
        banner: c.image_url_for("backdrop"),
        poster: c.image_url_for("poster"),
        banner_resized: c.image_url_for("backdrop", variant: "medium"),
        cover_resized: c.image_url_for("poster", variant: "medium"),
        content_type: c.content_type,
        year: c.year, category_ids: c.category_ids,
        images: {
          poster: c.image_variants_for("poster", only: allowed),
          backdrop: c.image_variants_for("backdrop", only: allowed)
        } }
    end

    render json: {
      contents: contents_data,
      categories: categories.map { |c| { id: c.id, name: c.name } }
    }
  end

  def shuffle_recommendations
    unless SiteSetting.enable_shuffle_recommendations
      render json: { error: "Shuffle recommendations is disabled" }, status: :forbidden
      return
    end

    recommendations = load_shuffle_recommendations
    Rails.logger.info("Shuffle recommendations: #{recommendations}")
    render json: recommendations, root: false
  end
end
