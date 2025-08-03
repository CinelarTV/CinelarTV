# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_admin

    private

    def verify_admin
      return if current_user.has_role?(:admin)

      redirect_to "/",
                  alert: "No tienes permisos suficientes para acceder a esta página."
    end
  end
end
