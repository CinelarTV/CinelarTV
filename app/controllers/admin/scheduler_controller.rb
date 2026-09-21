# frozen_string_literal: true

module Admin
  class SchedulerController < BaseController
    def trigger
      job_name = params[:name]
      halt 400, { error: "Missing job name" } if job_name.blank?

      begin
        klass = job_name.constantize
      rescue NameError
        halt 404, { error: "Job not found: #{job_name}" }
      end

      unless klass.respond_to?(:schedule_info)
        halt 400, { error: "#{job_name} is not a scheduled job" }
      end

      info = klass.schedule_info
      info.next_run = Time.now.to_i
      info.write!

      render json: { ok: true, message: "#{job_name} scheduled to run now" }
    end
  end
end
