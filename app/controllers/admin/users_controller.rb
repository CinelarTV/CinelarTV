# frozen_string_literal: true

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::BaseController
    def index
      @users = User.all
      respond_to do |format|
        format.html
        format.json do
          render json: {
            data: @users.as_json(only: %i[id email username created_at updated_at]),
          }
        end
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

    private

    def user_params
      params.require(:user).permit(:email, :username, :password)
    end
  end
end
