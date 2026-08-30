# frozen_string_literal: true

class XmltvFetchJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :xmltv, retry: 2

  every 1.hour

  def perform
    return unless SiteSetting.enable_live_tv

    XmltvSource.active.each do |source|
      XmltvParseJob.perform_async(source.id)
    end
  end
end
