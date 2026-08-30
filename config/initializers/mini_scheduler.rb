# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

if Sidekiq.server?
  Rails.application.config.after_initialize do
    # Clear stale mini_scheduler locks
    redis = Redis.new(url: ENV["REDIS_URL"])
    redis.keys("_scheduler_lock_*").each { |k| redis.del(k) }

    # Load plugin engines first (defines Live, WatchParty, etc. namespaces)
    Dir.glob(Rails.root.join("plugins", "*", "lib", "*", "engine.rb")).each { |f| require f }

    # Now load ALL job classes (core + plugins) so ObjectSpace can find them
    Dir.glob(Rails.root.join("app", "sidekiq", "*_job.rb")).each { |f| require f }
    Dir.glob(Rails.root.join("plugins", "*", "app", "sidekiq", "**", "*_job.rb")).each { |f| require f }

    MiniScheduler.configure do |config|
      config.redis = redis
    end

    begin
      MiniScheduler.start(workers: 5)
    rescue MiniScheduler::DistributedMutex::Timeout
      sleep 5
      retry
    end
  end
end
