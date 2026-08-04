class ContentsController < ApplicationController
  def search
    query = (params[:q] || params[:query]).to_s.strip

    if query.blank? || query.length < 2
      respond_to do |format|
        format.html
        format.json do
          render json: {
            errors: [
              I18n.t("contents.search.query_required")
            ],
            error_type: "query_required",
          }, status: :unprocessable_entity
        end
      end
      return
    end

    @contents = Content.search_by_title_and_description(query).limit(30)
    respond_to do |format|
      format.html
      format.json {
        render json: {
          data: @contents.as_json(only: %i[id title description banner content_type], methods: [:available])
        }
      }
    end
  end

  def show
    @content = Content.includes(:categories, :cast_members, :trailer_video_sources, seasons: :episodes)
                      .find_by(id: params[:id])

    raise CinelarTV::NotFound unless @content

    if CrawlerDetection.crawler?(request.user_agent)
      @is_crawler = true
      render :show, layout: "crawler", formats: [:html]
    else
      respond_to do |format|
        format.html
        format.json {
          # stale? retorna false (y renderiza 304 automáticamente) si el ETag/Last-Modified coincide.
          # Cache-Control: private (por liked/disliked per-profile) + must-revalidate.
          if stale?(@content, public: false)
            render json: ContentSerializer.new(@content, current_profile: current_profile).serializable_hash
          end
        }
      end
    end
  end

  private
end
