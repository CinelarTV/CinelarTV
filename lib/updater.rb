# frozen_string_literal: true

# lib/update.rb

require "io/wait"
require "open3"

module CinelarTV
  module Updater
    REMOTE_VERSION_CACHE_KEY = "updater_remote_version"
    REMOTE_VERSION_LAST_CHECKED_AT_KEY = "updater_remote_version_checked_at"
    REMOTE_VERSION_CACHE_TTL = 20.minutes

    def self.remote_version(force_refresh: false)
      return nil unless CinelarTV.is_git_repo?

      cached = remote_version_cache
      return cached if cached.present? && !force_refresh && !remote_version_stale?

      refreshed = refresh_remote_version_cache
      refreshed.presence || cached.presence
    end

    def self.refresh_remote_version_cache
      return nil unless CinelarTV.is_git_repo?

      version = `git ls-remote --heads origin test-passed 2>#{File::NULL}`.strip.split.first
      self.remote_version_cache = version
      self.remote_version_last_checked_at = Time.current
      version.presence
    rescue StandardError
      nil
    end

    def self.versions_diff
      return 0 unless CinelarTV.is_git_repo?

      rv = remote_version
      return 0 if rv.nil? || rv.empty?

      commits = `git rev-list #{CinelarTV.git_version}..#{rv} 2>#{File::NULL}`
      commits.split("\n").count
    end

    def self.updates_available?
      return false unless CinelarTV.is_git_repo?

      rv = remote_version
      return false if rv.nil? || rv.empty?

      CinelarTV.git_version != rv
    end

    def self.last_commit_message
      return "N/A" unless CinelarTV.is_git_repo?
      `git log --format=%s -n 1 2>#{File::NULL}`.strip
    end

    def self.last_updated_at
      CinelarTV.cache.read("updated_at")
    end

    def self.last_updated_at=(val)
      CinelarTV.cache.write("updated_at", val)
    end

    def self.remote_version_cache
      CinelarTV.cache.read(REMOTE_VERSION_CACHE_KEY)
    end

    def self.remote_version_cache=(val)
      CinelarTV.cache.write(REMOTE_VERSION_CACHE_KEY, val)
    end

    def self.remote_version_last_checked_at
      CinelarTV.cache.read(REMOTE_VERSION_LAST_CHECKED_AT_KEY)
    end

    def self.remote_version_last_checked_at=(val)
      CinelarTV.cache.write(REMOTE_VERSION_LAST_CHECKED_AT_KEY, val)
    end

    def self.remote_version_stale?
      checked_at = remote_version_last_checked_at
      checked_at.blank? || checked_at <= REMOTE_VERSION_CACHE_TTL.ago
    end

    def self.log(message)
      publish "log", "#{message}\n"
    end

    def self.publish(type, value)
      @admin_profile_ids = User.with_role(:admin).joins(:profiles).pluck("profiles.id").uniq

      MessageBus.publish("/admin/upgrade",
                         { type:, value: })
    end

    def self.percent(val)
      publish("percent", val)
    end

    def self.restart_server
      restart_puma
    end

    def self.restart_puma
      pid = Process.pid
      log("")
      log("********************************************************")
      log("***  CinelarTV Restart - This may take a couple of minutes  ***")
      log("********************************************************")
      log("")
      log("=> Puma PID: #{pid}")
      log("")
      percent(100)
      sleep 1 # Espera para asegurar que el frontend reciba el mensaje
      publish("status", "restarted")
      FileUtils.touch(Rails.root.join("tmp/restart.txt"))
      system("kill -USR2 #{pid}")
    end

    def self.run_update
      unless CinelarTV.is_git_repo?
        log("Not a Git repository. Attempting to fix...")

        unless try_to_fix_git_repo
          publish("status", "failed")
          log("Update failed: Could not initialize Git repository.")
          log("Please install from Git or set CINELAR_GIT_REPO environment variable.")
          return
        end
      end

      pid = Process.pid
      CinelarTV.maintenance_enabled = true
      begin
        if Rails.env.production?
          log("Stashing local changes to avoid conflicts...")
          run("git reset --hard")
        end

        percent(0)
        log("")
        log("")
        log("********************************************************")
        log("***  CinelarTV Update - This may take a few minutes  ***")
        log("********************************************************")
        log("")
        log("=> Puma PID: #{pid}")
        log("=> Current git hash: #{CinelarTV.git_version}")
        log("=> Current git branch: #{CinelarTV.git_branch}")
        log("=> Remote git hash: #{remote_version(force_refresh: true)}")
        log("=> Commit message: #{last_commit_message}")
        log("=> Versions diff: #{versions_diff}")
        log("")
        percent(5)
        log("")
        log("************** Enabling Maintenance Mode ***************")
        log("")
        percent(10)
        run("git fetch origin test-passed")
        percent(25)
        log("*** Installing Ruby Gems ***")
        run("bundle config set --local without 'development test'")
        run("bundle install --retry 3 --jobs 4")
        percent(30)
        log("*** Installing node modules ***")
        run("pnpm install --prefer-offline --no-audit")
        percent(50)
        log("*** Running Database Migrations ***")
        run("rake db:migrate")
        percent(65)
        percent(80)
        log("*** Bundling assets. This may take a while *** ")
        run("rake assets:precompile")
        percent(92)
        self.last_updated_at = Time.now
        percent(95)
        log("************** Disabling Maintenance Mode ***************")
        percent(100)
        log("DONE\n********************************************************\n***  CinelarTV Update - Complete!  ***\n********************************************************\n\n***  Restarting Puma  ***")
        publish("status", "complete")
        CinelarTV.maintenance_enabled = false
        restart_puma
      rescue StandardError => e
        publish("status", "failed")
        CinelarTV.maintenance_enabled = false
        [
          "FAILED TO UPGRADE",
          e.inspect,
          e.backtrace.join("\n"),
        ].each { |message| warn(message); log(message) }
      end
    end

    def self.run(cmd)
      log "$ #{cmd}"
      msg = +""

      retval = nil
      Open3.popen2e("cd #{Rails.root} && #{cmd} 2>&1") do |_in, out, wait_thread|
        out.each do |line|
          line.rstrip! # the client adds newlines, so remove the one we're given
          log(line)
          msg << line << "\n"
        end
        retval = wait_thread.value
      end

      return if retval == 0

      warn("FAILED: '#{cmd}' exited with a return value of #{retval}")
      warn(msg)
      CinelarTV.maintenance_enabled = false
      raise RuntimeError
    end

    def self.try_to_fix_git_repo
      return true if CinelarTV.is_git_repo?
      
      log("Attempting to initialize Git repository...")
      
      begin
        # Inicializar el repo
        run("git init")
        
        # Agregar el remote origin
        remote_url = ENV["CINELAR_GIT_REPO"] || "https://github.com/cinelartv/cinelartv.git"
        run("git remote add origin #{remote_url}")
        
        # Fetch el branch test-passed
        run("git fetch origin test-passed")
        
        # Hacer checkout al branch
        run("git checkout -b test-passed origin/test-passed")
        
        log("Git repository initialized successfully!")
        true
      rescue StandardError => e
        log("Failed to initialize Git repository: #{e.message}")
        false
      end
    end
  end
end
