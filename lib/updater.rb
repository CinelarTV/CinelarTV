# frozen_string_literal: true

# lib/update.rb

require "io/wait"

module CinelarTV
  module Updater
    def self.remote_version
      `git ls-remote --heads origin test-passed`.strip.split.first
    end

    def self.versions_diff
      commits = `git rev-list #{CinelarTV.git_version}..#{remote_version}`

      commits.split("\n").count
    end

    def self.updates_available?
      CinelarTV.git_version != remote_version # temporarily
    end

    def self.last_commit_message
      `git log --format=%s -n 1`
    end

    def self.last_updated_at
      CinelarTV.cache.read("updated_at")
    end

    def self.last_updated_at=(val)
      CinelarTV.cache.write("updated_at", val)
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
      pid = Process.pid

      log("")
      log("********************************************************")
      log("***  CinelarTV Restart - This may take a few minutes  ***")
      log("********************************************************")
      log("")
      log("=> Puma PID: #{pid}")
      log("")
      FileUtils.touch(Rails.root.join("tmp/restart.txt"))
      system("kill -USR2 #{pid}")
    end

    def self.run_update
      pid = Process.pid

      CinelarTV.maintenance_enabled = true

      # Stash all local changes before upgrading to avoid conflicts (Except on development)
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
      log("=> Remote git hash: #{remote_version}")
      log("=> Commit message: #{last_commit_message}")
      log("=> Versions diff: #{versions_diff}")
      log("")

      percent(5)
      log("")
      log("************** Enabling Maintenance Mode ***************")
      log("")
      percent(10)

      # Fetch the latest code from the repo
      run("git fetch origin test-passed")
      percent(25)

      log("*** Installing Ruby Gems ***")
      run("bundle install --retry 3 --jobs 4")

      run("bundle config set --local without 'development test'")

      percent(30)
      log("*** Installing node modules ***")
      run("yarn install --production")

      percent(50)

      log("*** Running Database Migrations ***")
      run("rake db:migrate")

      percent(65)

      percent(80)

      log("*** Bundling assets. This will take a while *** ")

      run("rake assets:precompile")

      percent(92)

      # Update the last updated at time

      self.last_updated_at = Time.now

      percent(95)

      log("************** Disabling Maintenance Mode ***************")

      percent(100)

      log("DONE")
      log("")
      log("********************************************************")
      log("***  CinelarTV Update - Complete!  ***")
      log("********************************************************")
      log("")
      log("")
      log("***  Restarting Puma  ***")
      publish("status", "complete")
      CinelarTV.maintenance_enabled = false

      FileUtils.touch(Rails.root.join("tmp/restart.txt"))
      system("kill -USR2 #{pid}")
    rescue StandardError => e
      publish("status", "failed")
      CinelarTV.maintenance_enabled = false

      [
        "FAILED TO UPGRADE",
        e.inspect,
        e.backtrace.join("\n"),
      ].each do |message|
        warn(message)
        log(message)
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
  end
end
