# frozen_string_literal: true

# app/models/concerns/reports/signups.rb
module Reports
  module Signups
    extend ActiveSupport::Concern

    class_methods do
      def report_signups(report)
        report.icon = "user-plus" # Customize the icon for signups report

        # Calculate the date range within which you want to generate the report
        date_range = (report.start_date.to_date..report.end_date.to_date)

        # Initialize an empty hash to store signup data by date
        signups_data = {}

        # Initialize the data hash with all dates in the range and zero signups
        date_range.each { |date| signups_data[date] = 0 }

        # Fetch and group signups data from the User model
        User
          .where("users.created_at >= ? AND users.created_at <= ?", report.start_date, report.end_date)
          .group("DATE(users.created_at)")
          .count
          .each { |date, count| signups_data[date.to_date] = count }

        # Convert the hash to an array of objects with x and y properties
        signups_data_array = signups_data.map { |date, count| { x: date.to_s, y: count } }

        report.data = signups_data_array
      end
    end
  end
end
