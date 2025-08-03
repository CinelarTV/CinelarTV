# frozen_string_literal: true

module JsonError
  def create_errors_json(obj, opts = nil)
    opts ||= {}

    errors = create_errors_array obj
    errors[:error_type] = opts[:type] if opts[:type]
    errors[:extras] = opts[:extras] if opts[:extras]
    errors
  end

  private

  def create_errors_array(obj)
    return { errors: [obj] } if obj.is_a?(String)

    obj = obj.record if obj.is_a?(ActiveRecord::RecordInvalid)

    return { errors: obj.errors.full_messages } if obj.respond_to?(:errors) && obj.errors.present?

    return { errors: obj.map(&:to_s) } if obj.is_a?(Array) && obj.present?

    if obj.is_a?(Exception)
      message = obj.cause.message.presence || obj.cause.class.name if obj.cause
      message = obj.message.presence || obj.class.name if message.blank?
      return { errors: [message] } if message.present?
    end

    return { errors: [I18n.t("not_found")] } if obj.is_a?(HasErrors) && obj.not_found

    Rails.logger.warn("create_errors_json called with unrecognized type: #{obj.inspect}") if obj
    JsonError.generic_error
  end

  def self.generic_error
    { errors: [I18n.t("js.generic_error")] }
  end
end
