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
      continue_watching = []

      # Obtén los elementos de ContinueWatching para el perfil actual
      continue_watching_items = ContinueWatching.where(profile_id: current_profile.id).order("updated_at DESC").limit(20)

      # Utiliza un hash para rastrear las series y sus episodios más recientes
      series_episodes = {}

      continue_watching_items.each do |cw|
        content = cw.content
        episode = cw.episode

        if episode.present? # Verifica si es una serie
          if !series_episodes.key?(content.id) || episode.updated_at > series_episodes[content.id][:episode].updated_at
            series_episodes[content.id] = {
              episode: episode,
              content: content,
            }
          end
        else
          # Si no es una serie (por ejemplo, una película), muestra la información tal como está en el objeto `cw`
          continue_watching << {
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

      # Agrega los episodios más recientes de las series a la lista `continue_watching`
      series_episodes.each do |content_id, data|
        continue_watching << {
          id: data[:content].id,
          title: data[:content].title,
          description: data[:content].description,
          banner: data[:content].banner,
          liked: liked_contents_ids&.include?(data[:content].id),
          # from continue_watching_items
          progress: continue_watching_items.find_by(content_id: data[:content].id).progress,
          duration: continue_watching_items.find_by(content_id: data[:content].id).duration,
          last_watched_at: continue_watching_items.find_by(content_id: data[:content].id).last_watched_at,
          episode: data[:episode].as_json(except: %i[created_at updated_at]),
        }
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
