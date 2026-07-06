# frozen_string_literal: true

class ScheduledLaunchJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    Content.publish_scheduled!
  end
end
