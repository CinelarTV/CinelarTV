# frozen_string_literal: true

module SectionKind
  BANNER = "banner"
  CONTINUE_WATCHING = "continue_watching"
  RECOMMENDED_FOR_YOU = "recommended_for_you"
  YOU_MIGHT_LIKE = "you_might_like"
  NEW_THIS_WEEK = "new_this_week"
  TRENDING = "trending"
  ADDED_RECENTLY = "added_recently"
  MOST_VIEWED = "most_viewed"
  MOST_LIKED = "most_liked"
  BY_GENRE = "by_genre"
  TOP_10_BY_COUNTRY = "top_10_by_country"

  ALL = [
    BANNER, CONTINUE_WATCHING, RECOMMENDED_FOR_YOU, YOU_MIGHT_LIKE,
    NEW_THIS_WEEK, TRENDING, ADDED_RECENTLY, MOST_VIEWED, MOST_LIKED,
    BY_GENRE, TOP_10_BY_COUNTRY
  ].freeze
end
