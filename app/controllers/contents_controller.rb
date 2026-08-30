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

    result = ContentSearchService.new(
      term: query,
      profile: current_profile,
      page: params[:page],
      per_page: params[:per_page]
    ).execute

    respond_to do |format|
      format.html
      format.json {
        render json: {
          data: result[:contents].as_json(only: %i[id title description banner content_type year], methods: [:available]),
          people: result[:people].as_json(only: %i[id name profile_path]),
          categories: result[:categories].as_json(only: %i[id name]),
          meta: result[:meta]
        }
      }
    end
  end

  def show
    @content = Content.includes(:categories, :trailer_video_sources, :image_variants,
                                cast_members: :person,
                                seasons: { episodes: :image_variants })
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
