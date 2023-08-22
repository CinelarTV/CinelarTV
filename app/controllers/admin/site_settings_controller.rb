# frozen_string_literal: true

module Admin
  class SiteSettingsController < Admin::BaseController
    def index
      respond_to do |format|
        format.html
        format.json do
          site_settings = SiteSetting.defined_fields

          response = site_settings.each_with_object([]) do |setting, memo|
            memo << {
              key: setting[:key],
              category: setting[:scope],
              default: setting[:default],
              type: setting[:type],
              readonly: setting[:readonly],
              value: SiteSetting.send(setting[:key]),
              options: setting[:options],
            } unless setting[:options][:hidden]
          end

          render json: { site_settings: response }
        end
      end
    end

    def create
      @errors = []
      setting_params.keys.each do |key|
        next if setting_params[key].nil?

        if key == "site_logo"
          # Si el campo es el de la imagen del sitio, cargar y procesar la imagen
          logo_uploader = LogoUploader.new
          logo_uploader.store!(setting_params[key])
          SiteSetting.send("#{key}=", logo_uploader.url)
        else
          # Si no, actualizar el valor de la configuración
          setting = SiteSetting.new(var: key)
          setting.value = setting_params[key].strip
          unless setting.valid?
            @errors << setting.errors.full_messages
          end
        end
      end

      if @errors.any?
        render json: { error: @errors.to_sentence }, status: :unprocessable_entity
      else
        setting_params.keys.each do |key|
          # Si el campo es el de la imagen del sitio, ya lo actualizamos, por lo que no necesitamos hacer nada aquí
          next if key == "site_logo"
          puts "Setting #{key} to #{setting_params[key]}"
          @new_value = setting_params[key]

          puts "Setting #{key} to #{@new_value}"
          SiteSetting.send("#{key}=", @new_value) unless setting_params[key].nil?
          update_carrierwave_setting if is_storage_related?(key)
        end

        render json: { message: 'I18n.t("js.core.success_settings")' }, status: :ok
      end
    end

    private

    def setting_params
      params.require(:setting).permit(settings_keys.map(&:to_sym))
    end

    def settings_keys
      SiteSetting.keys
    end

    def is_storage_related?(key)
      key == "storage_provider" || key == "s3_access_key_id" || key == "s3_secret_access_key" || key == "s3_bucket" || key == "s3_region" || key == "s3_endpoint"
    end

    def update_carrierwave_setting
      BaseUploader.configure do |config|
        config.storage = SiteSetting.storage_provider == "local" ? :file : :aws

        if config.storage == :aws
          config.aws_credentials = {
            access_key_id: SiteSetting.s3_access_key_id,
            secret_access_key: SiteSetting.s3_secret_access_key,
            region: SiteSetting.s3_region,
            endpoint: SiteSetting.s3_endpoint || "https://s3.#{SiteSetting.s3_region}.amazonaws.com",
          }
          config.aws_bucket = SiteSetting.s3_bucket
          config.aws_acl = "public-read"
        end
      end
    end
  end
end
