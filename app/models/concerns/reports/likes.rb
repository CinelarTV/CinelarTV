# frozen_string_literal: true

# app/models/concerns/reports/likes.rb
module Reports::Likes
  extend ActiveSupport::Concern

  class_methods do
    def report_likes(report)
      report.icon = "thumbs-up"

      # Calculate the date range within which you want to generate the report
      date_range = (report.start_date.to_date..report.end_date.to_date)

      # Initialize an empty hash to store likes data by date
      likes_data = {}

      # Initialize the data hash with all dates in the range and zero likes
      date_range.each { |date| likes_data[date] = 0 }

      # Fetch and group likes data from the Content model
      Content
        .joins(:liking_profiles)
        .where("contents.created_at >= ? AND contents.created_at <= ?", report.start_date, report.end_date)
        .group("DATE(contents.created_at)")
        .count
        .each { |date, count| likes_data[date.to_date] = count }

      # Convert the hash to an array of objects with x and y properties
      likes_data_array = likes_data.map { |date, count| { x: date.to_s, y: count } }

      report.data = likes_data_array
    end
  end
end
