# frozen_string_literal: true

module Admin
  class CustomPagesController < Admin::BaseController
    before_action :set_custom_page, only: %i[edit update destroy]

    def index
      @custom_pages = CustomPage.all
    end

    def create
      @custom_page = CustomPage.new(custom_page_params)
      if @custom_page.save
        render json: @custom_page, status: :created, location: @custom_page
      else
        render json: @custom_page.errors, status: :unprocessable_entity
      end
    end

    def update
      if @custom_page.update(custom_page_params)
        render json: @custom_page
      else
        render json: @custom_page.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @custom_page.destroy
      respond_to do |format|
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_custom_page
      @custom_page = CustomPage.find(params[:slug])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def custom_page_params
      params.require(:custom_page).permit(:title, :slug, :template, :metadata)
    end
  end
end
