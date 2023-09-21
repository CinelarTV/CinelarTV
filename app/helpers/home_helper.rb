# frozen_string_literal: true

module HomeHelper
  def homepage_data
    liked_contents_ids = liked_content_ids

    @homepage_data = {
      banner_content: load_banner_content(liked_contents_ids),
      content: [
        {
          title: I18n.t("js.home.added_recently"),
          content: load_added_recently(liked_contents_ids),
        },
      ],
    }

    add_recommended_based_on_liked(liked_contents_ids)
    add_continue_watching(liked_contents_ids)

    @homepage_data
  end

  private

  def liked_content_ids
    current_profile&.liked_contents&.pluck(:id) || []
  end

  def load_banner_content(liked_contents_ids)
    Content
      .where(available: true)
      .where.not(banner: nil)
      .order("RANDOM()")
      .limit(10)
      .pluck(:id, :title, :description, :banner)
      .map do |id, title, description, banner|
      {
        id: id,
        title: title,
        description: description,
        banner: banner,
        liked: liked_contents_ids.include?(id),
      }
    end
  end

  def load_added_recently(liked_contents_ids)
    Content
      .where(available: true)
      .where("created_at > ?", 3.week.ago)
      .order(created_at: :desc)
      .limit(15)
      .pluck(:id, :title, :description, :banner)
      .map do |id, title, description, banner|
      {
        id: id,
        title: title,
        description: description,
        banner: banner,
        liked: liked_contents_ids.include?(id),
      }
    end
  end

  def add_recommended_based_on_liked(liked_contents_ids)
    random_content = liked_content_ids.sample
    random_liked = Content.find_by(id: random_content)
    if random_liked.present?
      recommended_based_on_liked = random_liked
        .similar_items
        .pluck(:id, :title, :description, :banner)
        .map do |id, title, description, banner|
        {
          id: id,
          title: title,
          description: description,
          banner: banner,
          liked: liked_contents_ids.include?(id),
        }
      end

      @homepage_data[:content].insert(
        0,
        {
          title: I18n.t("js.home.because_you_liked", title: random_liked.title),
          content: recommended_based_on_liked.shuffle,
        }
      )
    end
  end

  def add_continue_watching(liked_contents_ids)
    if current_profile.present?
      continue_watching = ContinueWatching
        .select("DISTINCT ON (content_id) continue_watchings.*, contents.title, contents.description, contents.banner")
        .where(profile_id: current_profile.id)
        .joins(:content)
        .includes(:episode)
        .order("content_id, last_watched_at DESC")
        .limit(20)
        .map do |cw|
        content = cw.content
        episode = cw.episode

        {
          id: content.id,
          title: content.title,
          description: content.description,
          banner: content.banner,
          liked: liked_contents_ids.include?(content.id),
          progress: cw.progress,
          duration: cw.duration,
          last_watched_at: cw.last_watched_at,
          episode: episode&.as_json(except: %i[created_at updated_at]),
        }
      end

      if continue_watching.present?
        # Ahora, ordenamos la lista completa por last_watched_at en orden descendente
        continue_watching.sort_by! { |cw| cw[:last_watched_at] }.reverse!

        @homepage_data[:content].insert(
          0,
          {
            title: I18n.t("js.home.continue_watching"),
            content: continue_watching,
          }
        )
      end

      ip_address = nil

      if Rails.env.production?
        ip_address = request.remote_ip
      else
        begin
          ip_address = Net::HTTP.get(URI.parse("http://checkip.amazonaws.com/")).squish
        rescue StandardError => e
          Rails.logger.error "Error fetching IP address: #{e.message}"
        end
      end

      if ip_address.present?
        IpInfo.lookup(ip_address).tap do |ip_info|
          if CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}").present?
            # Merge the top 10 content by country with the homepage data
            @homepage_data[:content].insert(
              1,
              {
                title: I18n.t("js.home.top_10_content_by_country", country: ip_info[:country]),
                content: CinelarTV.cache.read("top_10_content_#{ip_info[:country_code]}"),
              }
            )
          end
        end
      end
    end
  end
end
