# frozen_string_literal: true

module Admin
  class EmailStylesController < BaseController
    def show
      render json: {
        id: "email-style",
        html: EmailStyle.new.html,
        css: EmailStyle.new.css,
        default_html: EmailStyle.default_template,
        default_css: EmailStyle.default_css
      }
    end

    def update
      updater = EmailStyleUpdater.new(current_user)
      if updater.update(params.require(:email_style).permit(:html, :css))
        render json: {
          id: "email-style",
          html: EmailStyle.new.html,
          css: EmailStyle.new.css,
          default_html: EmailStyle.default_template,
          default_css: EmailStyle.default_css
        }
      else
        render json: { errors: updater.errors }, status: :unprocessable_entity
      end
    end
  end
end
