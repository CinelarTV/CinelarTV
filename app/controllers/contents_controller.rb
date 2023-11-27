class ContentsController < ApplicationController
  def search
    query = params[:q] || params[:query]

    if query.blank?
      respond_to do |format|
        format.html
        format.json do
          render json: {
            errors: ["Query is required"],
            error_type: "query_required",
          }
        end
      end
      return
    end

    @contents = Content.search(query)
    respond_to do |format|
      format.html
      format.json { render json: { data: @contents.as_json(only: %i[id title description banner]) } }
    end
  end

  def show
    @content = Content.find_by(id: params[:id])

    raise CinelarTV::NotFound unless @content

    @data = {
      content: @content.as_json(except: %i[created_at updated_at url available]),
      liked: current_profile&.liked_contents&.include?(@content),
      related_content: @content.similar_items.as_json(only: %i[id title description banner]),
    }

    @data[:content][:available] = available?

    handle_seasons_and_episodes if @content.content_type == "TVSHOW"
    handle_continue_watching if @content.content_type == "MOVIE"

    respond_to do |format|
      format.html
      format.json {
        render json: ContentSerializer.new(@content, current_profile: current_profile).serializable_hash
      }
    end
  end

  private

  def available?
    if @content.content_type == "MOVIE"
      @content.available && !@content.video_sources.empty?
    elsif @content.content_type == "TVSHOW"
      @content.available && !@content.seasons.empty? && !@content.seasons.first.episodes.empty?
    end
  end

  def handle_seasons_and_episodes
    @data[:content][:seasons] = @content.seasons.order(position: :asc).map do |s|
      {
        id: s.id,
        title: s.title,
        description: s.description,
        position: s.position,
        episodes: s.episodes.order(position: :asc).map do |e|
          {
            id: e.id,
            title: e.title,
            description: e.description,
            thumbnail: e.thumbnail || @content.banner,
            position: e.position,
          }
        end,
      }
    end
  end

  def handle_continue_watching
    most_recent_watched_episode = ContinueWatching.where(profile: current_profile,
                                                         content: @content).order(updated_at: :desc).not(episode_id: nil).first if @content.content_type == "TVSHOW"
    continue_watching = ContinueWatching.where(profile: current_profile,
                                               content: @content).order(updated_at: :desc).first

    @data[:content][:most_recent_watched_episode] = most_recent_watched_episode.as_json(only: %i[episode_id progress duration]) if most_recent_watched_episode.present?
    @data[:content][:continue_watching] = continue_watching.as_json(only: %i[progress duration]) if continue_watching.present?
  end
end
