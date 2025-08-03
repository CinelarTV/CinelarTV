# frozen_string_literal: true

# app/models/concerns/reports/likes.rb
module Reports
  module Likes
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

        # Fetch and group likes
        ActiveRecord::Base.connection.execute("
  SELECT DATE(updated_at) AS date, COUNT(*) AS count
  FROM likes
  WHERE updated_at >= '#{report.start_date}' AND updated_at <= '#{report.end_date}'
  GROUP BY DATE(updated_at)
  ORDER BY date
").each { |row| likes_data[row["date"].to_date] = row["count"] }

        # Convert the hash to an array of objects with x and y properties
        likes_data_array = likes_data.map { |date, count| { x: date.to_s, y: count } }

        report.data = likes_data_array
      end
    end
  end
end
