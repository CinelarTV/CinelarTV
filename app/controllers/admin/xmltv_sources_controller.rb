# frozen_string_literal: true

module Admin
  class XmltvSourcesController < Admin::BaseController
    before_action :set_source, only: [:update, :destroy, :fetch, :channels]

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

    # Returns parsed channel list for the given XMLTV source.
    # Supports optional params: q (query), page, per_page, fetch (bool to re-fetch remote XML)
    def channels
      if params[:fetch].present?
        @source.fetch
      end

      xml = @source.raw_xml.to_s
      channel_list = []

      if xml.present?
        begin
          doc = Nokogiri::XML(xml)
          channel_list = doc.css('channel').map do |ch|
            {
              id: ch['id'],
              display_name: ch.at('display-name')&.text,
              icon: ch.at('icon')&.attr('src')
            }
          end
        rescue StandardError => e
          Rails.logger.error("Failed to parse XMLTV channels: #{e.message}")
        end
      end

      if params[:q].present?
        q = params[:q].to_s.downcase
        channel_list.select! do |c|
          (c[:display_name].to_s.downcase.include?(q)) || (c[:id].to_s.downcase.include?(q))
        end
      end

      total = channel_list.size
      page = [params[:page].to_i, 1].max
      per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
      paginated = channel_list.slice((page - 1) * per_page, per_page) || []

      respond_to do |format|
        format.json { render json: { channels: paginated, total: total, page: page, per_page: per_page } }
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
