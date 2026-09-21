# frozen_string_literal: true

module Auth
  class Registry
    BUILTIN_AUTHENTICATORS = [
      Auth::GoogleAuthenticator.new
    ].freeze

    def self.authenticators
      BUILTIN_AUTHENTICATORS
    end

    def self.enabled_authenticators
      authenticators.select(&:enabled?)
    end

    # Middleware registration is intentionally less strict than `enabled?`.
    # Credentials are loaded in the strategy setup phase on every request, so
    # changing them does not require rebuilding Rails' middleware stack.
    def self.middleware_authenticators
      authenticators.select(&:enabled_in_settings?)
    end

    def self.find_by_name(name)
      authenticators.find { |a| a.name == name }
    end
  end
end
