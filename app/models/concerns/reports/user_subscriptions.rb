# frozen_string_literal: true

module Reports
  module UserSubscriptions
    extend ActiveSupport::Concern

    class_methods do
      def report_user_subscriptions(report)
        report.icon = "subscription"

        date_range = (report.start_date.to_date..report.end_date.to_date)
        subscriptions_data = {}

        date_range.each { |date| subscriptions_data[date] = 0 }

        Subscription
          .where("subscriptions.created_at >= ? AND subscriptions.created_at <= ?", report.start_date, report.end_date)
          .group("DATE(subscriptions.created_at)")
          .count
          .each { |date, count| subscriptions_data[date.to_date] = count }

        report.data = subscriptions_data.map { |date, count| { x: date.to_s, y: count } }
      end
    end
  end
end
