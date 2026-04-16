# frozen_string_literal: true

class MediaScannerJob
  include Sidekiq::Job

  def perform
    return unless SiteSetting.enable_media_checker

    batch_size = SiteSetting.media_checker_batch_size || 100
    
    # Seleccionamos:
    # 1. Medios en estado 'uncertain' (prioridad absoluta para confirmar si están rotos)
    # 2. Medios 'verified' que no se han revisado en las últimas 24 horas
    sources_to_check = VideoSource.where(storage_location: "external_url")
                                  .where.not(media_status: "checking")
                                  .where("media_status = 'uncertain' OR last_checked_at IS NULL OR last_checked_at < ?", 1.day.ago)
                                  .order(media_status: :desc, last_checked_at: :asc) # 'uncertain' primero
                                  .limit(batch_size)

    sources_to_check.each_with_index do |source, index|
      # Espaciamos la ejecución de los workers para no saturar (throttling)
      VideoSourceMediaCheckerJob.perform_in(index * 2.seconds, source.id)
    end
  end
end
