# frozen_string_literal: true

# app/models/concerns/reports/completion_rate.rb
module Reports
  module CompletionRate
    extend ActiveSupport::Concern

    class_methods do
      def report_completion_rate(report)
        report.icon = "check-circle"
        report.title = I18n.t("reports.completion_rate.title")

        date_range = (report.start_date.to_date..report.end_date.to_date)
        completion_data = {}

        date_range.each { |date| completion_data[date] = 0.0 }

        WatchSession
          .where("started_at >= ? AND started_at <= ?", report.start_date, report.end_date)
          .group("DATE(started_at)")
          .pluck(Arel.sql("DATE(started_at), COUNT(CASE WHEN completed = true THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)"))
          .each { |date, rate| completion_data[date.to_date] = rate.round(1) }

        report.data = completion_data.map { |date, rate| { x: date.to_s, y: rate } }
      end
    end
  end
end
