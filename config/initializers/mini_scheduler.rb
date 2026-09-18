# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end

mini_scheduler_redis = Redis.new(url: ENV["REDIS_URL"])
MiniScheduler.configure do |config|
  config.redis = mini_scheduler_redis
end

if Sidekiq.server?
  Rails.application.config.after_initialize do
    # Clear stale mini_scheduler keys (locks, queues, and schedule entries)
    mini_scheduler_redis.keys("_scheduler_*").each { |k| mini_scheduler_redis.del(k) }

    # Load plugin engines first (defines Live, WatchParty, etc. namespaces)
    Dir.glob(Rails.root.join("plugins", "*", "lib", "*", "engine.rb")).each { |f| require f }

    # Load all job classes (core + plugins) so ObjectSpace can find them
    core_jobs = Dir.glob(Rails.root.join("app", "sidekiq", "*_job.rb"))
    plugin_jobs = Dir.glob(Rails.root.join("plugins", "*", "app", "sidekiq", "**", "*_job.rb"))

    (core_jobs + plugin_jobs).each do |f|
      require f
    rescue StandardError => e
      Rails.logger.error("[MiniScheduler] Failed to load #{f}: #{e.message}")
    end

    schedules = MiniScheduler::Manager.discover_schedules
    queues = MiniScheduler::Manager.discover_queues

    Rails.logger.info(
      "[MiniScheduler] Discovered #{schedules.size} schedules across #{queues.size} queues: " \
      "#{schedules.map(&:to_s)}"
    )

    if schedules.empty?
      Rails.logger.warn("[MiniScheduler] No schedules found! Scheduler will not run.")
      next
    end

    begin
      MiniScheduler.start(workers: 5)
      Rails.logger.info("[MiniScheduler] Started successfully with 5 workers")
    rescue MiniScheduler::DistributedMutex::Timeout
      Rails.logger.warn("[MiniScheduler] Could not acquire lock, retrying in 5s...")
      sleep 5
      retry
    rescue StandardError => e
      Rails.logger.error(
        "[MiniScheduler] Failed to start: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      )
    end
  end
end
