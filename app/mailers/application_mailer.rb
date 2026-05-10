# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV['CINELAR_SMTP_FROM'] || 'from@example.com'
  layout "mailer"
end
