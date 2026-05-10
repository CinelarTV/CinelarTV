# frozen_string_literal: true

class DeviseFailureApp < Devise::FailureApp

  def respond
    if warden_message == :unconfirmed
      # For SPA, return JSON for unconfirmed users using JsonError format
      self.status = 401
      self.content_type = 'application/json'
      body = begin
        if defined?(JsonError) && JsonError.respond_to?(:create_errors_json)
          JsonError.create_errors_json(i18n_message, type: "unconfirmed", extras: { needs_confirmation: true })
        elsif defined?(JsonError)
          Object.new.extend(JsonError).create_errors_json(i18n_message, type: "unconfirmed", extras: { needs_confirmation: true })
        else
          { errors: [i18n_message], error_type: "unconfirmed", extras: { needs_confirmation: true } }
        end
      rescue => e
        Rails.logger.error("DeviseFailureApp unconfirmed response failed: #{e.class} - #{e.message}")
        { errors: [i18n_message], error_type: "unconfirmed", extras: { needs_confirmation: true } }
      end
      self.response_body = body.to_json
    elsif json_request? || api_request?
      json_error_response
    else
      super
    end
  end

  private

  def json_error_response
    self.status = 401
    self.content_type = 'application/json'
    # Resolve JsonError at runtime (avoids autoload/initializer ordering issues)
    body = begin
      if warden_message == :unconfirmed
        {
          error: "unconfirmed",
          message: i18n_message,
          needs_confirmation: true
        }
      elsif defined?(JsonError) && JsonError.respond_to?(:create_errors_json)
        JsonError.create_errors_json(i18n_message)
      elsif defined?(JsonError)
        # JsonError defines instance methods (module style). Extend a temporary
        # object and call the instance method to get the same behavior.
        Object.new.extend(JsonError).create_errors_json(i18n_message)
      else
        { errors: [i18n_message] }
      end
    rescue => e
      Rails.logger.error("DeviseFailureApp json_error_response failed: #{e.class} - #{e.message}")
      { errors: [i18n_message] }
    end

    self.response_body = body.to_json
  end

  def json_request?
    request.format.json?
  end

  def api_request?
    request.path.start_with?("/api/")
  end
end
