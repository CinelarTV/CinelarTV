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

    added_recently = Content.where("created_at > ?", 3.week.ago).limit(15).map do |content|
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
      content: [
        {
          title: "Agregados recientemente",
          content: added_recently,
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

    @homepage_data
  end
end
