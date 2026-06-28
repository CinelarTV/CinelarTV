# frozen_string_literal: true

# app/models/concerns/reports/watch_time.rb
module Reports
  module WatchTime
    extend ActiveSupport::Concern

    class_methods do
      def report_watch_time(report)
        report.icon = "clock"
        report.title = I18n.t("reports.watch_time.title")

        date_range = (report.start_date.to_date..report.end_date.to_date)
        watch_time_data = {}

        date_range.each { |date| watch_time_data[date] = 0 }

        WatchSession
          .where("started_at >= ? AND started_at <= ?", report.start_date, report.end_date)
          .group("DATE(started_at)")
          .sum(:duration_watched)
          .each { |date, seconds| watch_time_data[date.to_date] = (seconds / 3600.0).round(2) }

        report.data = watch_time_data.map { |date, hours| { x: date.to_s, y: hours } }
      end
    end
  end
end
