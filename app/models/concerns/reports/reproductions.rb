# frozen_string_literal: true

# app/models/concerns/reports/reproductions.rb
module Reports
  module Reproductions
    extend ActiveSupport::Concern

    class_methods do
      def report_reproductions(report)
        report.icon = "play" # Personaliza el icono para el informe de reproducciones

        # Calcula el rango de fechas para el informe
        date_range = (report.start_date.to_date..report.end_date.to_date)

        # Inicializa un hash vacío para almacenar los datos de reproducciones por fecha
        reproductions_data = {}

        # Inicializa el hash de datos con todas las fechas en el rango y cero reproducciones
        date_range.each { |date| reproductions_data[date] = 0 }

        # Recupera y agrupa los datos de reproducciones del modelo Reproduction
        Reproduction
          .where("reproductions.played_at >= ? AND reproductions.played_at <= ?", report.start_date, report.end_date)
          .group("DATE(reproductions.played_at)")
          .count
          .each { |date, count| reproductions_data[date.to_date] = count }

        # Convierte el hash en un arreglo de objetos con propiedades x e y
        reproductions_data_array = reproductions_data.map { |date, count| { x: date.to_s, y: count } }

        report.data = reproductions_data_array
      end
    end
  end
end
