# frozen_string_literal: true

module Auth
  class Authenticator
    def name
      raise NotImplementedError
    end

    def display_name
      name.titleize
    end

    def enable_setting
      nil
    end

    def required_settings
      []
    end

    def configured?
      required_settings.all? { |s| SiteSetting.public_send(s).present? }
    end

    def enabled?
      enabled_in_settings? && configured?
    end

    # A strategy must remain mounted while an administrator edits its dynamic
    # credentials. Otherwise OmniAuth falls through to Rails and turns the
    # provider URL into a misleading RoutingError.
    def enabled_in_settings?
      enable_setting.present? && SiteSetting.public_send(enable_setting)
    end

    def register_middleware(omniauth)
      raise NotImplementedError
    end

    def after_authenticate(_auth_hash)
      raise NotImplementedError
    end

    def after_create_account(_user, _auth_hash)
      # Optional hook for subclasses
    end

    def can_connect_existing_user?
      SiteSetting.omniauth_allow_account_linking
    end

    def can_revoke?
      SiteSetting.omniauth_allow_account_linking
    end
  end
end
