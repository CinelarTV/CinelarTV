# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OAuth device authorizations", type: :request do
  let(:user) { create(:user) }
  let(:application) do
    Doorkeeper::Application.create!(
      name: "Mobile App",
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    )
  end

  describe "GET /oauth/device" do
    it "renders the SPA shell" do
      sign_in user

      get "/oauth/device"

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("application/index")
    end
  end

  describe "POST /oauth/device.json" do
    it "authorizes a device using a bearer token" do
      token = Doorkeeper::AccessToken.create!(
        application: application,
        resource_owner_id: user.id,
        scopes: "",
        expires_in: 1.hour
      )
      device_grant = Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
        application: application,
        device_code: "device-code",
        user_code: "ABCD-EFGH",
        expires_in: 5.minutes
      )

      post "/oauth/device.json",
           params: { user_code: "ABCD-EFGH" },
           headers: { "Authorization" => "Bearer #{token.token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to be_present
      expect(device_grant.reload.resource_owner_id).to eq(user.id)
      expect(device_grant.user_code).to be_nil
    end
  end
end
