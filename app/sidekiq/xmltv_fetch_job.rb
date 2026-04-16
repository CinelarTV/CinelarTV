# frozen_string_literal: true

require "sidekiq-scheduler"

class XmltvFetchJob
  include Sidekiq::Job

  sidekiq_options queue: :xmltv, retry: 2

  def self.setup_schedule
    # The interval is in seconds, min 300 (5m), max 86400 (24h)
    interval = SiteSetting.xmltv_refresh_interval

    if SiteSetting.enable_live_tv
      Sidekiq.set_schedule("fetch_xmltv", {
        "every" => ["#{interval}s"],
        "class" => "XmltvFetchJob",
        "queue" => "xmltv",
        "description" => "Fetch and parse XMLTV sources for Live TV program guide (dynamic)"
      })
    else
      Sidekiq.remove_schedule("fetch_xmltv")
    end
  end

  def perform
    return unless SiteSetting.enable_live_tv

    XmltvSource.active.each do |source|
      XmltvParseJob.perform_async(source.id)
    end
  end
end
