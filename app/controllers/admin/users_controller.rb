# frozen_string_literal: true

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::BaseController
    def index
      users = User.all
      if params[:query].present?
        q = params[:query].downcase
        users = users.where('LOWER(email) LIKE ? OR LOWER(username) LIKE ?', "%#{q}%", "%#{q}%")
      end
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
      per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 30
      users = users.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)
      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: users.as_json(only: %i[id email username created_at updated_at suspended suspended_until deactivated_at]),
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
          data: @user.as_json(only: %i[id email username created_at updated_at]),
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

      user_json = user.as_json(only: %i[id email username created_at updated_at suspended suspended_until suspended_reason deactivated_at deactivated_reason suspended_by_id deactivated_by_id])
      user_json[:suspended_by] = user.suspended_by&.slice(:id, :email, :username)
      user_json[:deactivated_by] = user.deactivated_by&.slice(:id, :email, :username)

      render json: { data: user_json }
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

    def user_params
      params.require(:user).permit(:email, :username, :password)
    end
  end
end
