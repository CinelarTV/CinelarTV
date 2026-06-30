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

    content = Content.where(available: true)

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

    categories = Category
      .joins(:contents)
      .where(contents: { available: true })
      .group("categories.id")
      .having("COUNT(contents.id) >= 1")
      .order(:name)

    render json: {
      contents: content.limit(50).pluck(:id, :title, :description, :banner, :content_type, :year).map { |id, title, desc, banner, type, year|
        { id: id, title: title, description: desc, banner: banner, content_type: type, year: year }
      },
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
