# frozen_string_literal: true

module Users
  class DeviseMailer < ApplicationMailer
    default from: -> { ENV['CINELAR_SMTP_FROM'] || 'from@example.com' }
    layout "mailer"

    after_action :apply_email_style

    def confirmation_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || ENV['CINELAR_BASE_URL'] || begin
        Rails.application.routes.url_helpers.root_url
      rescue NoMethodError
        "http://localhost:3000"
      end
      confirmation_url = options[:confirmation_url] || "#{base_url}/confirmation?confirmation_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_confirmation_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, confirmation_url: confirmation_url)
      )

      @subject = template[:subject]
      @recipient_email = record.email
      @email_body = template[:body]

      Rails.logger.info "[DeviseMailer] Sending confirmation_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      )
    end

    def reset_password_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || ENV['CINELAR_BASE_URL'] || begin
        Rails.application.routes.url_helpers.root_url
      rescue NoMethodError
        "http://localhost:3000"
      end
      edit_password_url = options[:edit_password_url] || "#{base_url}/users/password/edit?reset_password_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_reset_password_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, edit_password_url: edit_password_url)
      )

      @subject = template[:subject]
      @recipient_email = record.email
      @email_body = template[:body]

      Rails.logger.info "[DeviseMailer] Sending reset_password_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      )
    end

    def unlock_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || ENV['CINELAR_BASE_URL'] || begin
        Rails.application.routes.url_helpers.root_url
      rescue NoMethodError
        "http://localhost:3000"
      end
      unlock_url = options[:unlock_url] || "#{base_url}/users/unlock?unlock_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_unlock_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, unlock_url: unlock_url)
      )

      @subject = template[:subject]
      @recipient_email = record.email
      @email_body = template[:body]

      Rails.logger.info "[DeviseMailer] Sending unlock_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      )
    end

    def email_changed(record, options = {})
      template = EmailTemplateResolver.resolve(
        "devise_email_changed",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, new_email: options[:email])
      )

      @subject = template[:subject]
      @recipient_email = record.email
      @email_body = template[:body]

      Rails.logger.info "[DeviseMailer] Sending email_changed to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      )
    end

    def test_email(recipient_email, subject, body)
      @recipient_email = recipient_email
      @subject = subject
      @email_body = body

      mail(
        to: recipient_email,
        subject: subject,
        from: ENV['CINELAR_SMTP_FROM'] || 'from@example.com'
      ) do |format|
        format.html { render 'test_email' }
      end
    end

    private

    def apply_email_style
      body_part = message.html_part || message
      return unless body_part

      original_html = body_part.body.decoded
      styled_html = wrap_with_email_style(original_html)
      styled_html = Email::Styles.new(styled_html).format_basic.format_html.to_html
      body_part.body = styled_html
    end

    def build_variables(user, custom_vars = {})
      base_vars = {
        username: user.username,
        email: user.email,
        site_name: SiteSetting.site_name || "CinelarTV",
        site_url: SiteSetting.base_url
      }
      base_vars.merge(custom_vars)
    end
  end
end
