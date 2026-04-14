# frozen_string_literal: true

require "sidekiq-scheduler"

class XmltvFetchJob
  include Sidekiq::Job

  sidekiq_options queue: :xmltv, retry: 2

  def perform
    return unless SiteSetting.enable_live_tv

    XmltvSource.active.each do |source|
      XmltvParseJob.perform_async(source.id)
    end
  end
end
