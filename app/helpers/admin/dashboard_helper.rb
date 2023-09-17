# frozen_string_literal: true

module Admin
  module DashboardHelper
    def statistics
      # Top 3 liked content in the last 7 days

      start_of_week = Date.today.beginning_of_week
      end_of_week = Date.today.end_of_week

      most_liked_content_of_the_week = Content
                                       .joins(:liking_profiles)
                                       .where(liking_profiles: { created_at: start_of_week..end_of_week })
                                       .group("contents.id")
                                       .order("COUNT(liking_profiles.id) DESC")
                                       .limit(3)

      {
        most_liked_content_of_the_week: most_liked_content_of_the_week.map do |content|
          {
            id: content.id,
            title: content.title,
            description: content.description,
            banner: content.banner,
            likes: content.liking_profiles.count
          }
        end
      }
    end
  end
end
