# frozen_string_literal: true

class UserAccountController < ApplicationController
  before_action :authenticate_user!

  def update_email
    user = current_user
    unless user.valid_password?(params[:user][:current_password])
      render json: { error: "Contraseña incorrecta" }, status: :unprocessable_entity
      return
    end

    new_email = params[:user][:email]
    if user.update(email: new_email)
      render json: { message: "Email actualizado correctamente" }, status: :ok
    else
      render json: { error: user.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  def update_password
    user = current_user
    unless user.valid_password?(params[:user][:current_password])
      render json: { error: "Contraseña incorrecta" }, status: :unprocessable_entity
      return
    end

    new_password = params[:user][:password]
    if user.update(password: new_password, password_confirmation: params[:user][:password_confirmation])
      render json: { message: "Contraseña actualizada correctamente" }, status: :ok
    else
      render json: { error: user.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  def linked_accounts
    accounts = current_user.oauth_identities.map do |identity|
      {
        provider: identity.provider,
        email: identity.email,
        created_at: identity.created_at,
      }
    end
    render json: { accounts: accounts }, status: :ok
  end
end
