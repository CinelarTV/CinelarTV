# frozen_string_literal: true

# app/models/report.rb
class Report
  SCHEMA_VERSION = 1
  FILTERS = %i[start_date end_date category group].freeze

  include Reports::Likes
  include Reports::Signups
  include Reports::UserSubscriptions
  include Reports::Reproductions

  attr_accessor :type, :data, :start_date, :end_date, :labels, :filters, :available_filters, :icon, :title

  def initialize(type)
    @type = type
    @start_date ||= default_start_date
    @end_date ||= default_end_date
    @labels = default_labels
    @filters = {}
    @available_filters = {}
    @icon = "chart-bar"
    @title = I18n.t("reports.default.title")
    @data = []
  end

  def default_start_date
    30.days.ago.utc.beginning_of_day
  end

  def default_end_date
    Time.now.utc.end_of_day
  end

  def default_labels
    [
      { type: :date, property: :x, title: I18n.t("reports.default.labels.day") },
      { type: :number, property: :y, title: I18n.t("reports.default.labels.count") },
    ]
  end

  def as_json(_options = {})
    {
      type:,
      data:,
      labels:,
      filters:,
      available_filters:,
      icon:,
      title:,
    }
  end

  def self.add_report(name, &)
    singleton_class.instance_eval { define_method("report_#{name}", &) }
  end
end
