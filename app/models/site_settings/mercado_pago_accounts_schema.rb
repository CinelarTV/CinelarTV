# frozen_string_literal: true

module SiteSettings
  # JSON Schema definition for the `mercadopago_accounts` site setting.
  #
  # This setting allows configuring multiple MercadoPago accounts — one per
  # country/site_id — since MP credentials are not interoperable across countries.
  # Each account maps to a specific MP site (MLU=Uruguay, MLA=Argentina, etc.)
  # and carries its own credentials and offering price.
  #
  # Usage in site_settings.yml:
  #   mercadopago_accounts:
  #     type: json_schema
  #     json_schema: SiteSettings::MercadoPagoAccountsSchema
  #
  class MercadoPagoAccountsSchema
    SITE_IDS = %w[MLA MLB MLC MLM MPE MCO MLU].freeze

    def self.schema
      {
        "type" => "array",
        "items" => {
          "type" => "object",
          "title" => "MercadoPago Account",
          "properties" => {
            "site_id" => {
              "type" => "string",
              "title" => "Site ID (Country)",
              "description" => "MercadoPago country code. Each country requires a separate account.",
              "enum" => SITE_IDS,
              "enumTitles" => [
                "🇦🇷 Argentina (MLA)",
                "🇧🇷 Brazil (MLB)",
                "🇨🇱 Chile (MLC)",
                "🇲🇽 Mexico (MLM)",
                "🇵🇪 Peru (MPE)",
                "🇨🇴 Colombia (MCO)",
                "🇺🇾 Uruguay (MLU)"
              ]
            },
            "enabled" => {
              "type" => "boolean",
              "title" => "Enabled",
              "description" => "Enable this account. Disabled accounts are ignored.",
              "default" => true
            },
            "access_token" => {
              "type" => "string",
              "title" => "Access Token",
              "description" => "APP_USR-... or TEST-... access token for this country's account.",
              "minLength" => 1
            },
            "public_key" => {
              "type" => "string",
              "title" => "Public Key",
              "description" => "APP_USR-... or TEST-... public key for this country's account.",
              "minLength" => 1
            },
            "webhook_secret" => {
              "type" => "string",
              "title" => "Webhook Secret",
              "description" => "HMAC secret used to verify incoming webhooks for this account. Leave blank to skip signature verification (not recommended in production)."
            },
            "plan_id" => {
              "type" => "string",
              "title" => "Plan ID (optional)",
              "description" => "Existing preapproval_plan ID for this country. Leave blank to create preapprovals without a plan."
            },
            "application_id" => {
              "type" => "string",
              "title" => "Application ID (optional)",
              "description" => "MP application ID. Used to filter webhooks and plans belonging to your app."
            },
            "amount_cents" => {
              "type" => "integer",
              "title" => "Amount (cents)",
              "description" => "Subscription price in the smallest currency unit (e.g. 29900 = $299.00 UYU).",
              "minimum" => 1
            },
            "currency" => {
              "type" => "string",
              "title" => "Currency",
              "description" => "ISO 4217 currency code (UYU, ARS, BRL, CLP, MXN, PEN, COP).",
              "minLength" => 3,
              "maxLength" => 3
            }
          },
          "required" => %w[site_id access_token public_key amount_cents currency]
        },
        "uniqueItems" => true
      }
    end

    # Returns the account configuration for a given site_id from the parsed JSON value.
    # Falls back to nil if not found or not enabled.
    def self.account_for(site_id, accounts_json)
      return nil if accounts_json.blank?

      accounts = accounts_json.is_a?(Array) ? accounts_json : []
      accounts.find do |account|
        account.is_a?(Hash) &&
          account["site_id"].to_s.upcase == site_id.to_s.upcase &&
          account["enabled"] != false
      end
    end
  end
end
