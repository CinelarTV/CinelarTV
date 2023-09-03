# frozen_string_literal: true

# lib/wizard/builder.rb
class Wizard
  class Builder
    def initialize(user)
      @wizard = Wizard.new(user)
    end

    def build
      return @wizard unless @wizard.user.present?

      @wizard.append_step("introduction") do |step|
        step.emoji = "👋"
        step.banner = "/images/wizard/introduction.png"
        step.description = I18n.t("js.wizard.introduction.description")
      end

      @wizard.append_step("site_info") do |step|
        step.add_field(
          id: "site_name",
          type: "text",
          required: true,
          value: SiteSetting.site_name || "",
        )

        step.on_update do |updater|
          updater.apply_settings(:site_name)

          updater.refresh_required = true
        end
      end

      @wizard.append_step("license") do |step|
        step.emoji = "💸"

        step.add_field(
          id: "license_key",
          type: "text",
          required: true,
          value: SiteSetting.license_key || "",
        )

        step.on_update do |updater|
          # Activate the license, and set the license key (POST)

          activate_url = "https://api.lemonsqueezy.com/v1/licenses/activate"

          response = HTTParty.post(activate_url, {
            body: {
              license_key: updater.fields[:license_key],
              instance_name: "CTV_#{SecureRandom.hex(10)}",
            }.to_json,
            headers: {
              "Content-Type" => "application/json",
            },
          })

          if response.code == 200
            # La licencia se activó con éxito, puedes procesar la respuesta si es necesario
            Rails.logger.info("Licencia activada con éxito")
            Rails.logger.info("Respuesta: #{response.body}")

            updater.apply_settings(:license_key)
          else
            # La API devolvió un código de estado diferente de 200, lo que indica un error
            Rails.logger.error("Error al activar la licencia, código de estado: #{response.code}")
            Rails.logger.error("Respuesta: #{response.body}")

            updater.errors.add(:license_key, I18n.t("js.wizard.license.errors.invalid"))
          end
        end
      end

      @wizard.append_step("ready") do |step|
        step.emoji = "🎉"
        step.banner = "/images/wizard/ready.png"
        step.description = I18n.t("js.wizard.ready.description")

        step.on_update do |updater|
          SiteSetting.wizard_completed = true
        end
      end


      @wizard
    end
  end
end
