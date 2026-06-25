# frozen_string_literal: true

module Admin
  class EmailTemplatesController < BaseController
    include ActionView::Helpers::SanitizeHelper
    AVAILABLE_LOCALES = %w[en es pt-BR].freeze
    TEMPLATE_KEYS = %w[
      devise_confirmation_instructions
      devise_reset_password_instructions
      devise_unlock_instructions
      devise_email_changed
    ].freeze

    def index
      templates = {}
      TEMPLATE_KEYS.each do |key|
        templates[key] = {}
        AVAILABLE_LOCALES.each do |locale|
          override = EmailTemplate.for_key_and_locale(key, locale).first
          templates[key][locale] = {
            has_override: override.present?,
            interpolation_variables: get_interpolation_variables(key)
          }
        end
      end

      respond_to do |format|
        format.html do
          # HTML requests are handled by the SPA via dashboard#index
          # This shouldn't normally be hit, but if it does, redirect
          redirect_to '/admin/email-templates'
        end
        format.json do
          render json: { templates: }
        end
      end
    end

    def show
      respond_to do |format|
        format.json do
          template = find_template
          render json: {
            key: params[:key],
            locale: params[:locale],
            subject: template[:subject],
            body: template[:body],
            has_override: EmailTemplate.for_key_and_locale(params[:key], params[:locale]).exists?,
            interpolation_variables: get_interpolation_variables(params[:key])
          }
        end
      end
    end

    def update
      template = EmailTemplate.for_key_and_locale(params[:key], params[:locale]).first_or_initialize
      template.update!(
        subject: params[:subject],
        body: params[:body],
        interpolation_variables: get_interpolation_variables(params[:key])
      )

      Rails.logger.info "[EmailTemplate] Updated DB override for #{params[:key]}/#{params[:locale]}"

      render json: { success: true }
    end

    def destroy
      template = EmailTemplate.for_key_and_locale(params[:key], params[:locale]).first
      template&.destroy

      Rails.logger.info "[EmailTemplate] Reverted DB override for #{params[:key]}/#{params[:locale]}"

      render json: { success: true }
    end

    def preview
      template = find_template
      subject = template[:subject]
      body = template[:body]
      
      # Get interpolation variables
      variables = get_interpolation_variables(params[:key])
      
      # Create sample data for interpolation
      sample_data = {}
      variables.each do |var|
        case var
        when 'username'
          sample_data[var] = 'John Doe'
        when 'confirmation_url'
          sample_data[var] = "#{SiteSetting.site_url}/users/confirmation?confirmation_token=sample_token"
        when 'edit_password_url'
          sample_data[var] = "#{SiteSetting.site_url}/users/password/edit?reset_password_token=sample_token"
        when 'unlock_url'
          sample_data[var] = "#{SiteSetting.site_url}/users/unlock?unlock_token=sample_token"
        when 'site_name'
          sample_data[var] = SiteSetting.site_name || 'CinelarTV'
        when 'site_url'
          sample_data[var] = SiteSetting.site_url || 'https://example.com'
        when 'new_email'
          sample_data[var] = 'newemail@example.com'
        else
          sample_data[var] = "[#{var.upcase}]"
        end
      end
      
      # Interpolate variables
      interpolated_subject = subject.dup
      interpolated_body = body.dup
      
      sample_data.each do |key, value|
        interpolated_subject.gsub!("%{#{key}}", value.to_s)
        interpolated_body.gsub!("%{#{key}}", value.to_s)
      end
      
      # Create a temporary mailer instance for preview
      mailer = Class.new(ActionMailer::Base) do
        layout "mailer"
        def preview_email(subject, body, recipient_email)
          @subject = subject
          @recipient_email = recipient_email
          mail(
            to: recipient_email,
            subject: subject,
            from: ENV['CINELAR_SMTP_FROM'] || 'from@example.com'
          ) do |format|
            format.html { render html: body.html_safe }
          end
        end
      end
      
      # Generate the preview
      mail_instance = mailer.new.preview_email(interpolated_subject, interpolated_body, 'preview@example.com')
      
      # Get rendered HTML with layout
      layout_file = Rails.root.join('app', 'views', 'layouts', 'mailer.html.erb')
      layout_template = File.read(layout_file)
      
      # Replace ERB variables manually
      layout_content = layout_template.dup
      layout_content.gsub!('<%= @subject || SiteSetting.site_name || "CinelarTV" %>', interpolated_subject)
      layout_content.gsub!('<%= SiteSetting.site_name || "CinelarTV" %>', SiteSetting.site_name || 'CinelarTV')
      layout_content.gsub!('<%= Time.current.year %>', Time.current.year.to_s)
      layout_content.gsub!('<%= @recipient_email || \'you\' %>', 'preview@example.com')
      layout_content.gsub!('<%= SiteSetting.site_name || "CinelarTV" %>', SiteSetting.site_name || 'CinelarTV')
      layout_content.gsub!('<%= SiteSetting.site_url %>', SiteSetting.site_url || 'https://example.com')
      
      # Replace the yield placeholder with the actual email content
      final_html = layout_content.gsub('<%= yield %>', interpolated_body)
      
      render json: {
        subject: interpolated_subject,
        html: final_html,
        text: strip_tags(interpolated_body)
      }
    end

    private

    def find_template
      db_template = EmailTemplate.for_key_and_locale(params[:key], params[:locale]).first
      return { subject: db_template.subject, body: db_template.body } if db_template

      # Fall back to i18n YAML
      locale = params[:locale] || I18n.locale
      yaml_template = I18n.t("email_templates.#{params[:key]}", locale: locale, default: nil)
      
      unless yaml_template.is_a?(Hash) && yaml_template[:subject] && yaml_template[:body]
        raise ActiveRecord::RecordNotFound, "Template not found for key: #{params[:key]}, locale: #{locale}"
      end

      yaml_template
    end

    def get_interpolation_variables(key)
      case key
      when 'devise_confirmation_instructions'
        %w[username confirmation_url site_name site_url]
      when 'devise_reset_password_instructions'
        %w[username edit_password_url site_name site_url]
      when 'devise_unlock_instructions'
        %w[username unlock_url site_name site_url]
      when 'devise_email_changed'
        %w[username new_email site_name site_url]
      else
        %w[username site_name site_url]
      end
    end
  end
end
