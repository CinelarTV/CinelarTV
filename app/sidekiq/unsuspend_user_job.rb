# frozen_string_literal: true

class UnsuspendUserJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Only unsuspend if it was a temporary suspension and the time has passed
    if user.suspended && user.suspended_until.present? && user.suspended_until <= Time.current
      user.unsuspend!
    end
  rescue StandardError => e
    Rails.logger.error("UnsuspendUserJob failed for user #{user_id}: #{e.message}")
  end
end
