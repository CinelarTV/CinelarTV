# frozen_string_literal: true

module Admin
  class XmltvSourcesController < Admin::BaseController
    before_action :set_source, only: [:update, :destroy, :fetch]

    def index
      @sources = XmltvSource.order(:created_at)

      respond_to do |format|
        format.html
        format.json do
          render json: {
            xmltv_sources: @sources.map { |src| source_json(src) }
          }
        end
      end
    end

    def create
      @source = XmltvSource.new(source_params)

      if @source.save
        # Optionally trigger immediate fetch
        XmltvParseJob.perform_async(@source.id) if params[:fetch_now]

        respond_to do |format|
          format.html { redirect_to admin_xmltv_sources_path, notice: "XMLTV source created successfully." }
          format.json { render json: @source, status: :created }
        end
      else
        respond_to do |format|
          format.html { render :index, status: :unprocessable_entity }
          format.json { render json: { errors: @source.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if @source.update(source_params)
        respond_to do |format|
          format.html { redirect_to admin_xmltv_sources_path, notice: "XMLTV source updated successfully." }
          format.json { render json: @source }
        end
      else
        respond_to do |format|
          format.html { render :index, status: :unprocessable_entity }
          format.json { render json: { errors: @source.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @source.destroy
      respond_to do |format|
        format.html { redirect_to admin_xmltv_sources_path, notice: "XMLTV source deleted successfully." }
        format.json { head :no_content }
      end
    end

    def fetch
      XmltvParseJob.perform_async(@source.id)

      respond_to do |format|
        format.html { redirect_to admin_xmltv_sources_path, notice: "XMLTV fetch job queued." }
        format.json { render json: { message: "XMLTV fetch job queued" } }
      end
    end

    private

    def set_source
      @source = XmltvSource.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_error("XMLTV source not found", :not_found)
    end

    def source_params
      params.require(:xmltv_source).permit(:name, :url, :is_active)
    end

    def source_json(source)
      {
        id: source.id,
        name: source.name,
        url: source.url,
        is_active: source.is_active,
        last_fetched_at: source.last_fetched_at,
        last_parsed_at: source.last_parsed_at,
        created_at: source.created_at,
        updated_at: source.updated_at,
      }
    end

    def render_error(message, status)
      respond_to do |format|
        format.html { redirect_to admin_xmltv_sources_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
  end
end
