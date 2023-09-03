# frozen_string_literal: true

class StepsController < ApplicationController  
    before_action :authenticate_user!
  
    def update
      wizard = Wizard::Builder.new(current_user).build
      updater = wizard.create_updater(params[:id], params[:fields])

      
      updater.update
  
      if updater.success?
        result = { success: "OK" }
        result[:refresh_required] = true if updater.refresh_required?
        render json: result
      else
        errors = []
        updater.errors.messages.each do |field, msg|
          errors << { field: field, description: msg.join }
        end
        render json: { errors: errors }, status: 422
      end
    end
  end