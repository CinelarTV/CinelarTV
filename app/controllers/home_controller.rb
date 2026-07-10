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
      format.json { render json: homepage_data }
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

    case sort
    when "newest"
      content = content.order(created_at: :desc)
    when "most_liked"
      content = content.left_joins(:liking_profiles)
                       .group("contents.id")
                       .order(Arel.sql("COUNT(likes.profile_id) DESC"))
    else
      content = content.left_joins(:content_analytic)
                       .order(Arel.sql("COALESCE(content_analytics.total_views, 0) DESC"))
    end

    contents_data = content.limit(50).map do |c|
      { id: c.id, title: c.title, description: c.description, 
        banner: c.banner, banner_resized: c.banner_resized, 
        cover_resized: c.cover_resized, content_type: c.content_type, 
        year: c.year, category_ids: c.category_ids }
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
