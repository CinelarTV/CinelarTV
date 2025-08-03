# frozen_string_literal: true

class WizardController < ApplicationController
  before_action :authenticate_user!

  def index
    respond_to do |format|
      format.json do
        wizard = Wizard::Builder.new(current_user).build
        render json: wizard, serializer: WizardSerializer
      end

      format.html
    end
  end
end
