# frozen_string_literal: true

# application_controller_spec.rb

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  describe "#require_finish_installation?" do
    controller(ApplicationController) do
      def index
        head :ok
      end
    end

    context "when waiting_on_first_user is true and path does not start with /finish-installation" do
      before do
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(true)
        request.env["PATH_INFO"] = "/some-page"
      end

      it "redirects to /finish-installation" do
        get :index

        expect(response).to redirect_to("/finish-installation")
      end
    end
  end
end
