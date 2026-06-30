module EmailHelper
  def email_html_template(preview: nil, &block)
    email_content = capture { yield }
    email_preview = preview.present? ? ERB::Util.html_escape(preview) : ""

    dark_mode_meta = <<~HTML
      <meta name="color-scheme" content="light dark" />
      <meta name="supported-color-schemes" content="light dark" />
    HTML

    dark_mode_styles = <<~CSS
      <style>
        @media (prefers-color-scheme: dark) {
          body { background-color: #1a1a1a !important; }
          .email-container { background-color: #2d2d2d !important; border-color: #404040 !important; }
          .email-body { color: #e9ecef !important; }
          .email-body p, .email-body h1, .email-body h2, .email-body h3, .email-body span { color: #e9ecef !important; }
          .email-footer { background: #2d2d2d !important; color: #adb5bd !important; border-color: #404040 !important; }
          .highlight-box { background: rgba(255,255,255,0.06) !important; border-color: rgba(255,255,255,0.12) !important; }
        }
      </style>
    CSS

    html_lang = I18n.locale.to_s

    template = EmailStyle.new.html
    template = template.sub("%{email_content}") { email_content }
    template = template.gsub("%{email_preview}", email_preview)
    template = template.gsub("%{html_lang}", html_lang)
    template = template.gsub("%{dark_mode_meta_tags}", dark_mode_meta)
    template = template.gsub("%{dark_mode_styles}", dark_mode_styles)

    template.html_safe
  end
end
