# frozen_string_literal: true

module HomeHelper
  def homepage_data
    liked_contents_ids = current_profile&.liked_contents&.pluck(:id)

    random_liked = Content.where(id: liked_contents_ids).order("RANDOM()").limit(1).first
    recommended_based_on_liked = nil
    Rails.logger.info("random_liked: #{random_liked}")
    if random_liked.present?
      recommended_based_on_liked = random_liked.similar_items&.map do |content|
        {
          id: content.id,
          title: content.title,
          description: content.description,
          banner: content.banner,
          liked: liked_contents_ids&.include?(content.id),
        }
      end
    end

    added_recently = Content.where(available: true).where("created_at > ?", 3.week.ago).limit(15).map do |content|
      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        liked: liked_contents_ids&.include?(content.id),
      }
    end

    @homepage_data = {
      banner_content: Content.where(available: true).where.not(banner: nil).order("RANDOM()").limit(10).map do |content|
        {
          id: content.id,
          title: content.title,
          description: content.description,
          banner: content.banner,
          liked: liked_contents_ids&.include?(content.id),
        }
      end,
      content: [
        {
          title: "Agregados recientemente",
          content: added_recently.reverse,
        },
      ],
    }

    if recommended_based_on_liked.present? && !recommended_based_on_liked.empty?
      @homepage_data[:content].insert(
        0,
        {
          title: "Porque te gustó #{random_liked.title}",
          content: recommended_based_on_liked.shuffle,
        }
      )
    end

    # Continue watching for the current profile, if the content is a TV Show, then
    # get the latest episode watched, otherwise, get the movie (with times of course)

    if current_profile.present?
      continue_watching = ContinueWatching.where(profile_id: current_profile.id).order("updated_at DESC").limit(20).map do |cw|
        content = cw.content
        episode = cw.episode

        if episode.present? # Verifica si es una serie
          latest_episode = ContinueWatching.where(profile_id: current_profile.id, content_id: content.id).order("last_watched_at DESC").first
          {
            id: content.id,
            title: content.title,
            description: content.description,
            banner: content.banner,
            liked: liked_contents_ids&.include?(content.id),
            progress: latest_episode.progress,
            duration: latest_episode.duration,
            last_watched_at: latest_episode.updated_at,
            episode: latest_episode.as_json(except: %i[created_at updated_at]),
          }
        else
          # Si no es una serie (por ejemplo, una película), muestra la información tal como está en el objeto `cw`
          {
            id: content.id,
            title: content.title,
            description: content.description,
            banner: content.banner,
            liked: liked_contents_ids&.include?(content.id),
            progress: cw.progress,
            duration: cw.duration,
            last_watched_at: cw.last_watched_at,
          }
        end
      end

      if continue_watching.present? && !continue_watching.empty?
        @homepage_data[:content].insert(
          0,
          {
            title: "Continuar viendo",
            content: continue_watching,
          }
        )
      end
    end

    @homepage_data
  end
end
