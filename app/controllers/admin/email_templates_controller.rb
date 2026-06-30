# frozen_string_literal: true

module Admin
  class EmailTemplatesController < BaseController
    include ActionView::Helpers::SanitizeHelper

    AVAILABLE_LOCALES = %w[en es pt-BR].freeze

    SAMPLE_DATA = {
      'username' => 'John Doe',
      'email' => 'john@example.com',
      'confirmation_url' => ->(s) { "#{s}/users/confirmation?confirmation_token=sample_token" },
      'edit_password_url' => ->(s) { "#{s}/users/password/edit?reset_password_token=sample_token" },
      'unlock_url' => ->(s) { "#{s}/users/unlock?unlock_token=sample_token" },
      'site_name' => ->(_s) { SiteSetting.site_name || 'CinelarTV' },
      'site_url' => ->(_s) { SiteSetting.site_url || 'https://example.com' },
      'new_email' => 'newemail@example.com'
    }.freeze

    def index
      templates = {}
      template_keys.each do |key|
        templates[key] = {}
        meta = EmailTemplateResolver.available_templates[key]
        AVAILABLE_LOCALES.each do |locale|
          override = EmailTemplate.for_key_and_locale(key, locale).first
          templates[key][locale] = {
            has_override: override.present?,
            interpolation_variables: meta ? meta[:variables] : []
          }
        end
        templates[key][:meta] = {
          label: I18n.t("js.admin.email_templates.keys.#{key}", default: key),
          description: I18n.t("js.admin.email_templates.descriptions.#{key}", default: key)
        }
      end

      respond_to do |format|
        format.html { redirect_to '/admin/email-templates' }
        format.json { render json: { templates: } }
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

      interpolated_subject, interpolated_body = interpolate_templates(subject, body)

      layout_file = Rails.root.join('app', 'views', 'layouts', 'mailer.html.erb')
      layout_template = File.read(layout_file)

      final_html = render_with_layout(layout_template, interpolated_subject, interpolated_body)

      render json: {
        subject: interpolated_subject,
        html: final_html,
        text: strip_tags(interpolated_body)
      }
    end

    def test_send
      recipient = params[:recipient_email]
      unless recipient.present? && URI::MailTo::EMAIL_REGEXP.match?(recipient)
        return render json: { error: 'Invalid email address' }, status: :unprocessable_entity
      end

      template = find_template
      subject = template[:subject]
      body = template[:body]

      interpolated_subject, interpolated_body = interpolate_templates(subject, body)

      Users::DeviseMailer.test_email(
        recipient,
        interpolated_subject,
        interpolated_body
      ).deliver_later

      Rails.logger.info "[EmailTemplate] Test email sent to #{recipient} for template #{params[:key]}"

      render json: { success: true, message: "Test email sent to #{recipient}" }
    end

    private

    def template_keys
      EmailTemplateResolver.available_templates.keys
    end

    def find_template
      locale = params[:locale] || SiteSetting.default_locale || I18n.locale

      db_template = EmailTemplate.for_key_and_locale(params[:key], locale).first
      return { subject: db_template.subject, body: db_template.body } if db_template

      yaml_template = I18n.t("email_templates.#{params[:key]}", locale: locale, default: nil)

      unless yaml_template.is_a?(Hash) && yaml_template[:subject] && yaml_template[:body]
        raise ActiveRecord::RecordNotFound, "Template not found for key: #{params[:key]}, locale: #{locale}"
      end

      yaml_template
    end

    def get_interpolation_variables(key)
      meta = EmailTemplateResolver.available_templates[key]
      return meta[:variables] if meta

      subject = I18n.t("email_templates.#{key}.subject", locale: :en, default: '')
      body = I18n.t("email_templates.#{key}.body", locale: :en, default: '')
      EmailTemplateResolver.extract_variables(subject, body)
    end

    def interpolate_templates(subject, body)
      variables = get_interpolation_variables(params[:key])
      site_url = SiteSetting.site_url || 'https://example.com'

      interpolated_subject = subject.dup
      interpolated_body = body.dup

      variables.each do |var|
        value = case SAMPLE_DATA[var]
                when Proc then SAMPLE_DATA[var].call(site_url)
                when String then SAMPLE_DATA[var]
                else "[#{var.upcase}]"
                end

        interpolated_subject.gsub!("%{#{var}}", value.to_s)
        interpolated_body.gsub!("%{#{var}}", value.to_s)
      end

      [interpolated_subject, interpolated_body]
    end

    def render_with_layout(_layout_content, subject, body)
      layout_path = Rails.root.join('app', 'views', 'layouts', 'mailer.html.erb')
      layout_src = File.read(layout_path)

      layout_src.gsub!('<%= yield %>', 'MAILER_BODY_PLACEHOLDER')

      @subject = subject
      @recipient_email = 'preview@example.com'

      rendered = ERB.new(layout_src).result(binding)
      rendered.gsub('MAILER_BODY_PLACEHOLDER', body)
    end
  end
end
