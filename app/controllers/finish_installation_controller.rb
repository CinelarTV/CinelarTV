# frozen_string_literal: true

class FinishInstallationController < ApplicationController
  layout "finish_installation"

  def index; end

  def create_account
    @allowed_emails = find_allowed_emails

    @user = User.new

    return unless request.post?

    email = params[:email].strip
    username = params[:username].strip
    respond_to do |format|
      if @allowed_emails.include?(email)
        @user = User.new(email:, username:, password: params[:password])
        if @user.save
          # Set devise session
          sign_in(@user)
          format.html { redirect_to "/wizard" }
          format.json { render json: { message: "User created successfully", status: :ok } }
        else
          format.html { render :register }
          format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
        end
      else
        format.html { render :register }
        format.json do
          render json: { errors: ["Email not allowed"], error_type: "email_not_allowed" }, status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def find_allowed_emails
    return [] unless SiteSetting.developer_emails.present?

    SiteSetting.developer_emails.split(",").map(&:strip)
  end
end
