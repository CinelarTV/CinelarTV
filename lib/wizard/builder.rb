# lib/wizard/builder.rb
class Wizard
    class Builder
      def initialize(user)
        @wizard = Wizard.new(user)
      end
  
      def build
        return @wizard unless @wizard.user.present?

        @wizard.append_step("introduction") do |step|
          step.emoji = '👋'
          step.banner = '/images/wizard/introduction.png'
          step.description = I18n.t("js.wizard.introduction.description")
          
        end

  
        @wizard.append_step("site_info") do |step|

          step.add_field(
            id: "site_name",
            type: "text",
            required: true,
            value: SiteSetting.site_name || ""
          )
          
          step.add_field(id: "site_logo", type: "image", value: SiteSetting.site_logo)
  
          step.on_update do |updater|
            Rails.logger.info "Updating site name to #{updater.fields[:site_name]}"
            updater.apply_setting(:site_name)
            
            
          end
        end

        @wizard.append_step("license") do |step|
          step.emoji = '💸'

            step.add_field(
                id: "license",
                type: "text",
                required: true,
                value: SiteSetting.license_key || ""
            )

            step.on_update do |updater|
                # Check if license is valid calling the API
                # updater.ensure_changed(:license)
                # updater.apply_setting(:license)

                # if SiteSetting.license != updater.fields[:license]

            end
        end
  
        @wizard
      end
    end
  end
  