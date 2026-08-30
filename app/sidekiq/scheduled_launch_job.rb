# frozen_string_literal: true

class ScheduledLaunchJob
  include Sidekiq::Job
  extend MiniScheduler::Schedule

  sidekiq_options queue: :default

  every 1.hour

  def perform
    Content.publish_scheduled!
  end
end
