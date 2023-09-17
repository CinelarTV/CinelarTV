# frozen_string_literal: true

# app/models/concerns/reports/user_subscriptions.rb
module Reports
  module UserSubscriptions
    extend ActiveSupport::Concern

    class_methods do
      def report_user_subscriptions(report)
        report.icon = "subscription" # Personaliza el icono para el informe de suscripciones

        # Calcula el rango de fechas dentro del cual deseas generar el informe
        date_range = (report.start_date.to_date..report.end_date.to_date)

        user_subscriptions_data = {}

        date_range.each { |date| user_subscriptions_data[date] = 0 }

        # Obtiene y agrupa los datos de suscripciones desde el modelo UserSubscription
        UserSubscription
          .where("user_subscriptions.created_at >= ? AND user_subscriptions.created_at <= ?", report.start_date, report.end_date)
          .group("DATE(user_subscriptions.created_at)")
          .count
          .each { |date, count| user_subscriptions_data[date.to_date] = count }

        # Convierte el hash en un array de objetos con propiedades x e y
        user_subscriptions_data_array = user_subscriptions_data.map { |date, count| { x: date.to_s, y: count } }

        report.data = user_subscriptions_data_array
      end
    end
  end
end
