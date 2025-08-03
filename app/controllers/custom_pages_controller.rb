# frozen_string_literal: true

# app/controllers/custom_pages_controller.rb
class CustomPagesController < ApplicationController
  def show
    # Obtén la URL dinámica de la ruta catch-all
    requested_path = params[:path]

    # Busca una página personalizada por slug que coincida con la URL dinámica
    @custom_page = CustomPage.find_by(slug: requested_path)

    if @custom_page
      # Si se encuentra una página personalizada, muestra su contenido
      render :show
    else
      # For now, we'll just render the normal layout (Due to the single page app)
      render "application/index"
    end
  end
end
