# frozen_string_literal: true

class EmailTemplateResolver
  class TemplateNotFoundError < StandardError; end

  VARIABLE_PATTERN = /%\{(\w+)\}/

  def self.resolve(key, locale, variables = {})
    new(key, locale, variables).resolve
  end

  def self.extract_variables(subject, body)
    combined = "#{subject} #{body}"
    combined.scan(VARIABLE_PATTERN).flatten.uniq
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

  def self.available_templates
    keys = I18n.t("email_templates", locale: :en, default: {}).keys
    keys.each_with_object({}) do |key, hash|
      template = I18n.t("email_templates.#{key}", locale: :en, default: nil)
      next unless template.is_a?(Hash) && template[:subject] && template[:body]

      hash[key] = {
        subject: template[:subject],
        body: template[:body],
        variables: extract_variables(template[:subject], template[:body])
      }
    end
  end

  private

  def find_template
    db_template = EmailTemplate.for_key_and_locale(@key, @locale).first
    if db_template
      Rails.logger.info "[EmailTemplate] Using DB override for #{@key}/#{@locale}"
      return { subject: db_template.subject, body: db_template.body }
    end

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
