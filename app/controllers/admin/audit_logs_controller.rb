# frozen_string_literal: true

module Admin
  class AuditLogsController < BaseController
    def index
      logs = AuditLog.includes(:user, :target_user)

      logs = apply_filters(logs)

      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 50).to_i.clamp(1, 200)
      total = logs.count

      logs = logs.order(created_at: :desc)
                 .offset((page - 1) * per_page)
                 .limit(per_page)

      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: logs.map { |log| audit_log_json(log) },
            meta: {
              total: total,
              page: page,
              per_page: per_page,
              total_pages: (total.to_f / per_page).ceil
            }
          }
        end
      end
    end

    def actions
      respond_to do |format|
        format.html
        format.json do
          render json: {
            actions: AuditLog::ACTION_LABELS,
            custom_actions: AuditLog.custom_actions,
            registered_events: AuditLog.registered_events
          }
        end
      end
    end

    private

    def apply_filters(logs)
      logs = logs.by_user(params[:user_id]) if params[:user_id].present?
      logs = logs.by_target_user(params[:target_user_id]) if params[:target_user_id].present?
      logs = logs.by_action_type(params[:action_type]) if params[:action_type].present?
      logs = logs.by_source(params[:source]) if params[:source].present?

      if params[:auditable_type].present? && params[:auditable_id].present?
        logs = logs.by_auditable(params[:auditable_type], params[:auditable_id])
      end

      logs = logs.where("created_at >= ?", Time.zone.parse(params[:from])) if params[:from].present?
      logs = logs.where("created_at <= ?", Time.zone.parse(params[:to])) if params[:to].present?

      logs
    rescue ArgumentError
      logs
    end

    def audit_log_json(log)
      {
        id: log.id,
        action: log.action,
        action_label: log.human_action,
        custom_type: log.custom_type,
        subject: log.subject,
        description: log.description_for_user,
        previous_value: log.previous_value,
        new_value: log.new_value,
        details: log.details,
        source: log.source,
        result: log.result,
        context: log.context,
        user: log.user ? { id: log.user.id, username: log.user.username, email: log.user.email } : nil,
        target_user: if log.target_user
                       { id: log.target_user.id, username: log.target_user.username,
                         email: log.target_user.email }
                     end,
        auditable_type: log.auditable_type,
        auditable_id: log.auditable_id,
        ip_address: log.ip_address,
        created_at: log.created_at
      }
    end
  end
end
