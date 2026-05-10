# frozen_string_literal: true

module Admin
  class CategoriesController < Admin::BaseController
    before_action :set_category, only: [:show, :update, :destroy]

    def index
      categories = Category.all.order(:name)
      respond_to do |format|
        format.html
        format.json { render json: { data: categories } }
      end
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: { data: @category } }
      end
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        respond_to do |format|
          format.html { redirect_to admin_categories_path, notice: "Category created successfully" }
          format.json { render json: { data: @category, message: "Category created successfully" }, status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if @category.update(category_params)
        respond_to do |format|
          format.html { redirect_to admin_categories_path, notice: "Category updated successfully" }
          format.json { render json: { data: @category, message: "Category updated successfully" } }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      if @category.destroy
        respond_to do |format|
          format.html { redirect_to admin_categories_path, notice: "Category deleted successfully" }
          format.json { render json: { message: "Category deleted successfully" } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_categories_path, alert: "Failed to delete category" }
          format.json { render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def populate_from_tmdb
      return render json: { error: "TMDB API Key is not set" }, status: :unprocessable_entity if SiteSetting.tmdb_api_key.blank?

      configure_tmdb_api
      created_categories = []
      skipped_categories = []

      # Fetch movie genres from TMDB
      movie_genres = Tmdb::Genre.movie_list
      movie_genres.each do |genre|
        tmdb_id = genre["id"]
        name = genre["name"]

        # Check if category already exists with this tmdb_id
        existing_category = Category.find_by(tmdb_id: tmdb_id)

        if existing_category
          skipped_categories << existing_category
        else
          # Create new category
          category = Category.create(
            name: name,
            description: "TMDB genre: #{name}",
            tmdb_id: tmdb_id
          )
          created_categories << category if category.persisted?
        end
      end

      # Also fetch TV genres (they might have different IDs)
      tv_genres = Tmdb::Genre.tv_list
      tv_genres.each do |genre|
        tmdb_id = genre["id"]
        name = genre["name"]

        # Check if category already exists with this tmdb_id
        existing_category = Category.find_by(tmdb_id: tmdb_id)

        if existing_category
          skipped_categories << existing_category
        else
          # Create new category
          category = Category.create(
            name: name,
            description: "TMDB TV genre: #{name}",
            tmdb_id: tmdb_id
          )
          created_categories << category if category.persisted?
        end
      end

      respond_to do |format|
        format.json { render json: {
          message: "Categories populated from TMDB successfully",
          created: created_categories.count,
          skipped: skipped_categories.count,
          created_categories: created_categories,
          skipped_categories: skipped_categories
        } }
      end
    rescue Tmdb::Error => e
      render json: { error: "TMDB API error: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
    end

    private

    def set_category
      @category = Category.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Category not found" }, status: :not_found
    end

    def category_params
      params.require(:category).permit(:name, :description, :tmdb_id)
    end

    def configure_tmdb_api
      api_key = SiteSetting.tmdb_api_key.strip
      Tmdb::Api.key(api_key)
      Tmdb::Api.language(SiteSetting.default_locale)
      Rails.logger.info("Using TMDB API Key: #{api_key}")
    end
  end
end
