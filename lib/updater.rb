# lib/update.rb

require "io/wait"

module CinelarTV
  module Updater
    def self.remote_version
      `git ls-remote --heads origin main`.strip.split.first
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

    def self.log(message)
      publish "log", message + "\n"
    end

    def self.publish(type, value)
      @user_id ||= current_user.id if current_user
      MessageBus.publish("/admin/upgrade",
                         { type:, value: },
                         user_ids: [@user_id])
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
        log("Stashing local changes...")
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
      log("=> Remote git hash: #{remote_version}")
      log("=> Commit message: #{last_commit_message}")
      log("=> Versions diff: #{versions_diff}")
      log("")

      percent(5)
      log("")
      log("************** Enabling Maintenance Mode ***************")
      log("")
      percent(10)

      run("git pull")
      percent(25)

      run("bundle install")

      percent(30)
      run("yarn install --production")

      percent(50)

      run("rake db:migrate")

      percent(65)

      percent(80)

      log("*** Bundling assets. This will take a while *** ")

      run("rake assets:precompile")

      percent(92)
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
