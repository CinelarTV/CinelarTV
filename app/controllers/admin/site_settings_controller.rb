# frozen_string_literal: true

module Admin
  class SiteSettingsController < Admin::BaseController
    def index
      respond_to do |format|
        format.html
        format.json do
          site_settings = SiteSetting.defined_fields

          response = site_settings.each_with_object([]) do |setting, memo|
            # Exclude internal settings scope
            next if setting[:scope] == :internal

            next if setting[:options][:hidden]

            memo << {
              key: setting[:key],
              category: setting[:scope],
              default: setting[:default],
              type: setting[:type],
              readonly: setting[:readonly],
              value: SiteSetting.send(setting[:key]),
              options: setting[:options],
            }
          end

          render json: { site_settings: response }
        end
      end
    end

    def update
      @errors = []
      setting_params.each_key do |key|
        next if setting_params[key].nil?

        if %w[site_logo site_mobile_logo site_favicon].include?(key)
          logo_uploader = LogoUploader.new
          image_payload = key == "site_favicon" ? resized_favicon_blob(setting_params[key]) : setting_params[key]
          logo_uploader.store!(image_payload)
          SiteSetting.send("#{key}=", logo_uploader.url)
        else
          # Si no, actualizar el valor de la configuración
          setting = SiteSetting.new(var: key)
          value = setting_params[key]
          setting.value = value.respond_to?(:strip) ? value.strip : value
          @errors << setting.errors.full_messages unless setting.valid?
        end
      end

      if @errors.any?
        render json: { error: @errors.to_sentence }, status: :unprocessable_entity
      else
        setting_params.each_key do |key|
          # Si el campo es el de la imagen del sitio, ya lo actualizamos, por lo que no necesitamos hacer nada aquí
          next if %w[site_logo site_mobile_logo site_favicon].include?(key)

          SiteSetting.send("#{key}=", setting_params[key]) unless setting_params[key].nil?
        end

        update_carrierwave_setting if is_storage_related?(setting_params.keys)

        render json: { message: I18n.t("settings.saved_successfully") }, status: :ok
      end
    end

    def test_storage_connection
      result = test_connection

      if result[:success]
        render json: { success: true, message: result[:message], details: result[:details] }, status: :ok
      else
        render json: { success: false, error: result[:error], details: result[:details] }, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      params.require(:setting).permit(settings_keys.map(&:to_sym))
    end

    def settings_keys
      SiteSetting.keys
    end

    def is_storage_related?(keys)
      @related_keys ||= %w[storage_provider s3_access_key_id s3_secret_access_key s3_bucket s3_region s3_endpoint]
      Array(keys).map(&:to_s).any? { |key| @related_keys.include?(key) }
    end

    def resized_favicon_blob(uploaded_file)
      image = MiniMagick::Image.read(uploaded_file.read)
      image.resize "32x32"
      image.to_blob
    end

    def update_carrierwave_setting
      BaseUploader.configure_storage
    end

    def test_connection
      storage_provider = SiteSetting.storage_provider

      if storage_provider == 'local'
        return {
          success: true,
          message: "Local storage is configured",
          details: { storage_provider: "local" }
        }
      end

      # Check required S3 settings
      required_settings = %w[s3_access_key_id s3_secret_access_key s3_bucket]
      missing_settings = required_settings.reject { |setting| SiteSetting.send(setting).present? }

      if missing_settings.any?
        return {
          success: false,
          error: "Missing required settings",
          details: { missing_settings: missing_settings }
        }
      end

      # Build S3 client
      s3_client = Aws::S3::Client.new(
        access_key_id: SiteSetting.s3_access_key_id,
        secret_access_key: SiteSetting.s3_secret_access_key,
        region: SiteSetting.s3_region || 'us-east-1',
        endpoint: SiteSetting.s3_endpoint.presence
      )

      # Test connection by checking bucket access
      begin
        bucket_name = SiteSetting.s3_bucket

        # Try to list objects in the bucket (works for both AWS S3 and R2)
        response = s3_client.list_objects_v2(bucket: bucket_name, max_keys: 1)

        details = {
          storage_provider: "s3",
          bucket: bucket_name,
          region: SiteSetting.s3_region || 'us-east-1',
          endpoint: SiteSetting.s3_endpoint.presence || 'AWS Standard',
          bucket_accessible: true
        }

        {
          success: true,
          message: "Connection successful and bucket is accessible",
          details: details
        }
      rescue Aws::S3::Errors::NoSuchBucket => e
        {
          success: false,
          error: "Bucket '#{SiteSetting.s3_bucket}' does not exist or you don't have access",
          details: { error_type: e.class.name }
        }
      rescue Aws::S3::Errors::AccessDenied => e
        {
          success: false,
          error: "Access denied to bucket '#{SiteSetting.s3_bucket}'. Check your credentials and permissions",
          details: { error_type: e.class.name }
        }
      rescue Aws::S3::Errors::ServiceError => e
        {
          success: false,
          error: "Connection failed: #{e.message}",
          details: { error_type: e.class.name }
        }
      rescue StandardError => e
        {
          success: false,
          error: "Unexpected error: #{e.message}",
          details: { error_type: e.class.name }
        }
      end
    end
  end
end
