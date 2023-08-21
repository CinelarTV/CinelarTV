# frozen_string_literal: true

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::BaseController
    def index
      @users = User.all
      respond_to do |format|
        format.html
        format.json {
          render json: {
            data: @users.as_json(only: [:id, :email, :username, :created_at, :updated_at]),
          }
        }
      end
    end
  end
end
