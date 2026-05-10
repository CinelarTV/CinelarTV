# frozen_string_literal: true

# Configure ActionMailer to use SMTP settings from environment variables
Rails.application.configure do
  # Only configure SMTP if environment variables are present
  if ENV['CINELAR_SMTP_ADDRESS'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['CINELAR_SMTP_ADDRESS'],
      port: ENV['CINELAR_SMTP_PORT'] || 587,
      domain: ENV['CINELAR_SMTP_DOMAIN'],
      user_name: ENV['CINELAR_SMTP_USERNAME'],
      password: ENV['CINELAR_SMTP_PASSWORD'],
      authentication: ENV['CINELAR_SMTP_AUTHENTICATION'] || 'plain',
      enable_starttls_auto: ENV['CINELAR_SMTP_ENABLE_STARTTLS_AUTO'] != 'false',
      openssl_verify_mode: ENV['CINELAR_SMTP_OPENSSL_VERIFY_MODE'] || 'none'
    }.compact
  end

  # Set default URL options for mailer links
  config.action_mailer.default_url_options = {
    host: ENV['CINELAR_SMTP_HOST'] || 'localhost',
    port: ENV['CINELAR_SMTP_PORT'] || 3000
  }
end
