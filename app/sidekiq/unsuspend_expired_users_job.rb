# frozen_string_literal: true

class UnsuspendExpiredUsersJob
  include Sidekiq::Job

  def perform
    User.where(suspended: true).where.not(suspended_until: nil).where('suspended_until <= ?', Time.current).find_each do |user|
      begin
        user.unsuspend!
      rescue StandardError => e
        Rails.logger.error("UnsuspendExpiredUsersJob failed for user #{user.id}: #{e.message}")
      end
    end
  end
end
