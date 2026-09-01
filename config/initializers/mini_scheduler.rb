# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

# Configure MiniScheduler Redis for both web UI (Puma) and Sidekiq processes
# so the Scheduler tab can read schedule state from Redis
mini_scheduler_redis = Redis.new(url: ENV["REDIS_URL"])
MiniScheduler.configure do |config|
  config.redis = mini_scheduler_redis
end

if Sidekiq.server?
  Rails.application.config.after_initialize do
    # Clear stale mini_scheduler locks
    mini_scheduler_redis.keys("_scheduler_lock_*").each { |k| mini_scheduler_redis.del(k) }

    # Load plugin engines first (defines Live, WatchParty, etc. namespaces)
    Dir.glob(Rails.root.join("plugins", "*", "lib", "*", "engine.rb")).each { |f| require f }

    # Now load ALL job classes (core + plugins) so ObjectSpace can find them
    Dir.glob(Rails.root.join("app", "sidekiq", "*_job.rb")).each { |f| require f }
    Dir.glob(Rails.root.join("plugins", "*", "app", "sidekiq", "**", "*_job.rb")).each { |f| require f }

    begin
      MiniScheduler.start(workers: 5)
    rescue MiniScheduler::DistributedMutex::Timeout
      sleep 5
      retry
    end
  end
end
