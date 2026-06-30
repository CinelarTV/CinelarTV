# frozen_string_literal: true

class SendConfirmationReminderJob
  include Sidekiq::Job

  # Send reminder emails to unconfirmed users whose deadline is within 3 days.
  # Runs daily via sidekiq-scheduler.
  def perform
    deadline_window = User::CONFIRMATION_PERIOD
    reminder_window = 3.days

    # Users who are not confirmed, have a confirmation_sent_at, and whose
    # deadline falls within the next 3 days (i.e. between now and now+3d).
    User.where(confirmed_at: nil)
        .where.not(confirmation_sent_at: nil)
        .where('confirmation_sent_at + interval ? > ? AND confirmation_sent_at + interval ? <= ? + interval ?',
               deadline_window.to_i.seconds.to_s, Time.current,
               deadline_window.to_i.seconds.to_s, Time.current, reminder_window.to_i.seconds.to_s)
        .find_each do |user|
      Rails.logger.info "[ConfirmationReminder] Sending reminder to #{user.email} (deadline: #{user.confirmation_deadline})"
      Users::DeviseMailer.confirmation_instructions(user, user.confirmation_token).deliver_later
    rescue StandardError => e
      Rails.logger.error "[ConfirmationReminder] Failed for user #{user.id}: #{e.message}"
    end
  end
end
