# frozen_string_literal: true

class EmailTemplateResolver
  class TemplateNotFoundError < StandardError; end

  def self.resolve(key, locale, variables = {})
    new(key, locale, variables).resolve
  end

  def initialize(key, locale, variables = {})
    @key = key
    @locale = locale
    @variables = variables
  end

  def resolve
    template = find_template

    Rails.logger.info "[EmailTemplate] Resolving template: #{@key} for locale: #{@locale}"

    {
      subject: interpolate(template[:subject]),
      body: interpolate(template[:body])
    }
  rescue KeyError => e
    Rails.logger.error "[EmailTemplate] Missing interpolation variable: #{e.message} for template: #{@key}"
    raise
  end

  private

  def find_template
    # Try DB override first
    db_template = EmailTemplate.for_key_and_locale(@key, @locale).first
    if db_template
      Rails.logger.info "[EmailTemplate] Using DB override for #{@key}/#{@locale}"
      return { subject: db_template.subject, body: db_template.body }
    end

    # Fall back to i18n YAML
    Rails.logger.warn "[EmailTemplate] No DB override found, using YAML fallback for #{@key}/#{@locale}"
    yaml_template = I18n.t("email_templates.#{@key}", locale: @locale, default: nil)
    
    unless yaml_template.is_a?(Hash) && yaml_template[:subject] && yaml_template[:body]
      raise TemplateNotFoundError, "Template not found for key: #{@key}, locale: #{@locale}"
    end

    { subject: yaml_template[:subject], body: yaml_template[:body] }
  end

  def interpolate(string)
    return string if string.blank?

    string % @variables
  end
end
