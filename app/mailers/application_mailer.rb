# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV['CINELAR_SMTP_FROM'] || 'from@example.com'
  layout "mailer"

  protected

  def wrap_with_email_style(html)
    style = EmailStyle.new
    preview_text = @subject || ""

    dark_mode_meta = <<~HTML.strip
      <meta name="color-scheme" content="light dark" />
      <meta name="supported-color-schemes" content="light dark" />
    HTML

    dark_mode_styles = <<~HTML.strip
      <style>
        @media (prefers-color-scheme: dark) {
          body { background-color: #1a1a1a !important; }
          .email-container { background-color: #2d2d2d !important; border-color: #404040 !important; }
          .email-body { color: #e9ecef !important; }
          .email-body p, .email-body h1, .email-body h2, .email-body h3, .email-body span,
          .email-body strong, .email-body a { color: #e9ecef !important; }
          .email-footer { background: #2d2d2d !important; color: #adb5bd !important; border-color: #404040 !important; }
        }
      </style>
    HTML

    template = style.html
    template = template.sub("%{email_content}") { html }
    template = template.gsub("%{email_preview}", ERB::Util.html_escape(preview_text))
    template = template.gsub("%{html_lang}", SiteSetting.default_locale || I18n.locale.to_s)
    template = template.gsub("%{dark_mode_meta_tags}", dark_mode_meta)
    template = template.gsub("%{dark_mode_styles}", dark_mode_styles)
    template
  end
end
