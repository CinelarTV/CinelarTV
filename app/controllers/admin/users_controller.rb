# frozen_string_literal: true

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::BaseController
    def index
      users = User.includes(:profiles, :roles)
      if params[:query].present?
        q = params[:query].downcase
        users = users.where('LOWER(email) LIKE ? OR LOWER(username) LIKE ?', "%#{q}%", "%#{q}%")
      end
      if params[:status].present? && params[:status] != 'all'
        case params[:status]
        when 'active'
          users = users.where(suspended: [false, nil]).where(deactivated_at: nil)
        when 'suspended'
          users = users.where(suspended: true)
        when 'deactivated'
          users = users.where.not(deactivated_at: nil)
        end
      end
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 30
      sort_field = %w[created_at username email].include?(params[:sort]) ? params[:sort] : 'created_at'
      sort_dir = params[:dir] == 'asc' ? :asc : :desc
      users = users.order(sort_field => sort_dir).offset((page - 1) * per_page).limit(per_page)
      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: users.map { |u| user_json(u) },
          }
        end
      end
    end

    def destroy
      user = User.find_by(id: params[:id])
      unless user
        render json: { error: 'Not found' }, status: :not_found
        return
      end

      if user == current_user
        render json: { error: "Can't delete current user" }, status: :forbidden
        return
      end

      if user.destroy
        render json: { success: true }
      else
        render json: { error: 'Could not delete user' }, status: :unprocessable_entity
      end
    end

    # Allow admins to create users

    def create_user
      raise CinelarTV::NotFound unless SiteSetting.allow_admin_to_create_users

      @user = User.new(user_params)
      if @user.save
        render json: {
          data: user_json(@user),
        }
      else
        render json: {
          data: @user.errors,
        }
      end
    end

    def show
      user = User.find_by(id: params[:id])
      return render(json: { error: 'Not found' }, status: :not_found) unless user

      json = user_json(user)
      json[:suspended_by] = user.suspended_by&.slice(:id, :email, :username)
      json[:deactivated_by] = user.deactivated_by&.slice(:id, :email, :username)

      render json: { data: json }
    end

    # Admin actions: suspend, unsuspend, deactivate, activate
    def suspend
      user = User.find_by(id: params[:id])
      return render(json: { error: 'Not found' }, status: :not_found) unless user
      return render(json: { error: "Can't suspend current user" }, status: :forbidden) if user == current_user

      until_time = params[:until].present? ? (Time.zone.parse(params[:until]) rescue nil) : nil
      reason = params[:reason]
      user.suspend!(until_time, reason, current_user)
      render json: { success: true }
    end

    def unsuspend
      user = User.find_by(id: params[:id])
      return render(json: { error: 'Not found' }, status: :not_found) unless user
      user.unsuspend!
      render json: { success: true }
    end

    def deactivate
      user = User.find_by(id: params[:id])
      return render(json: { error: 'Not found' }, status: :not_found) unless user
      return render(json: { error: "Can't deactivate current user" }, status: :forbidden) if user == current_user

      reason = params[:reason]
      user.deactivate!(current_user, reason)
      render json: { success: true }
    end

    def activate
      user = User.find_by(id: params[:id])
      return render(json: { error: 'Not found' }, status: :not_found) unless user
      user.activate!
      render json: { success: true }
    end

    private

    def user_json(user)
      profile = user.profiles&.first
      {
        id: user.id,
        email: user.email,
        username: user.username,
        admin: user.has_role?(:admin),
        moderator: user.has_role?(:moderator),
        created_at: user.created_at,
        updated_at: user.updated_at,
        suspended: user.suspended?,
        suspended_until: user.suspended_until,
        suspended_reason: user.suspended_reason,
        deactivated_at: user.deactivated_at,
        deactivated_reason: user.deactivated_reason,
        avatar_id: profile&.avatar_id,
        profile_name: profile&.name
      }
    end

    def user_params
      params.require(:user).permit(:email, :username, :password)
    end
  end
end
