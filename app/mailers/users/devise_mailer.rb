# frozen_string_literal: true

module Users
  class DeviseMailer < ApplicationMailer
    default from: "from@example.com"

    def confirmation_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || Rails.application.routes.url_helpers.root_url
      confirmation_url = options[:confirmation_url] || "#{base_url}/confirmation?confirmation_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_confirmation_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, confirmation_url: confirmation_url)
      )

      Rails.logger.info "[DeviseMailer] Sending confirmation_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      ) do |format|
        format.html { render html: template[:body].html_safe }
      end
    end

    def reset_password_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || Rails.application.routes.url_helpers.root_url
      edit_password_url = options[:edit_password_url] || "#{base_url}/users/password/edit?reset_password_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_reset_password_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, edit_password_url: edit_password_url)
      )

      Rails.logger.info "[DeviseMailer] Sending reset_password_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      ) do |format|
        format.html { render html: template[:body].html_safe }
      end
    end

    def unlock_instructions(record, token, options = {})
      base_url = SiteSetting.base_url || Rails.application.routes.url_helpers.root_url
      unlock_url = options[:unlock_url] || "#{base_url}/users/unlock?unlock_token=#{token}"
      template = EmailTemplateResolver.resolve(
        "devise_unlock_instructions",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, unlock_url: unlock_url)
      )

      Rails.logger.info "[DeviseMailer] Sending unlock_instructions to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      ) do |format|
        format.html { render html: template[:body].html_safe }
      end
    end

    def email_changed(record, options = {})
      template = EmailTemplateResolver.resolve(
        "devise_email_changed",
        SiteSetting.default_locale || I18n.locale,
        build_variables(record, new_email: options[:email])
      )

      Rails.logger.info "[DeviseMailer] Sending email_changed to #{record.email}"

      mail(
        to: record.email,
        subject: template[:subject]
      ) do |format|
        format.html { render html: template[:body].html_safe }
      end
    end

    private

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
