# frozen_string_literal: true

module HomeHelper
  def homepage_data
    liked_contents_ids = current_profile&.liked_contents&.pluck(:id)

    added_recently = Content.where("created_at > ?", 3.week.ago).limit(15).map do |content| # El contenido con menos de 3 semanas de antiguedad se considera reciente
      {
        id: content.id,
        title: content.title,
        description: content.description,
        banner: content.banner,
        liked: liked_contents_ids&.include?(content.id),
      }
    end

    @homepage_data = {
      banner_content: Content.where.not(banner: nil).order("RANDOM()").limit(10).map do |content|
        {
          id: content.id,
          title: content.title,
          description: content.description,
          banner: content.banner,
          liked: liked_contents_ids&.include?(content.id),
        }
      end,
      content: {
        added_recently: added_recently,
      },
    }

    @homepage_data
  end
end
