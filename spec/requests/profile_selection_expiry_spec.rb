# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile selection expiry", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:profile) { user.profiles.first || create(:profile, user: user) }

  def create_token(profile_id: nil, last_activity: nil)
    Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application_id: nil,
      token: SecureRandom.hex(32),
      refresh_token: SecureRandom.hex(32),
      expires_in: 2.hours,
      scopes: "",
      current_profile_id: profile_id,
      profile_last_activity_at: last_activity
    )
  end

  def user_payload(body)
    body["current_user"] || body
  end

  describe "POST /session/select-profile with session (web)" do
    before { allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(12) }

    it "stores profile id and activity timestamp in the session" do
      sign_in user

      post "/session/select-profile", params: { profile_id: profile.id }

      expect(response).to have_http_status(:ok)
      expect(session[:current_profile_id]).to eq(profile.id)
      expect(session[:profile_last_activity_at]).to be_present
    end
  end

  describe "POST /session/select-profile with Doorkeeper token" do
    before { allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(12) }

    it "stores profile id and activity timestamp on the token" do
      token = create_token
      headers = { "Authorization" => "Bearer #{token.token}" }

      post "/session/select-profile", params: { profile_id: profile.id }, headers: headers

      expect(response).to have_http_status(:ok)
      token.reload
      expect(token.current_profile_id).to eq(profile.id)
      expect(token.profile_last_activity_at).to be_present
    end
  end

  describe "GET /session/current" do
    before { allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(12) }

    it "returns current_profile after a valid web session selection" do
      sign_in user
      post "/session/select-profile", params: { profile_id: profile.id }

      get "/session/current.json"

      expect(response).to have_http_status(:ok)
      body = user_payload(JSON.parse(response.body))
      expect(body["current_profile"]).to be_present
      expect(body["current_profile"]["id"]).to eq(profile.id)
    end

    it "returns current_profile null when doorkeeper profile selection expired" do
      token = create_token(profile_id: profile.id, last_activity: 13.hours.ago)

      get "/session/current.json", headers: { "Authorization" => "Bearer #{token.token}" }

      expect(response).to have_http_status(:ok)
      body = user_payload(JSON.parse(response.body))
      expect(body["current_profile"]).to be_nil
      expect(token.reload.current_profile_id).to be_nil
    end

    it "returns current_profile for a valid doorkeeper selection" do
      token = create_token(profile_id: profile.id, last_activity: Time.current)

      get "/session/current.json", headers: { "Authorization" => "Bearer #{token.token}" }

      expect(response).to have_http_status(:ok)
      body = user_payload(JSON.parse(response.body))
      expect(body["current_profile"]).to be_present
      expect(body["current_profile"]["id"]).to eq(profile.id)
    end

    it "clears expired doorkeeper profile and returns null current_profile" do
      token = create_token(profile_id: profile.id, last_activity: 2.days.ago)

      get "/session/current.json", headers: { "Authorization" => "Bearer #{token.token}" }

      body = user_payload(JSON.parse(response.body))
      expect(body["current_profile"]).to be_nil
      expect(token.reload.current_profile_id).to be_nil
    end
  end

  describe "HTML navigation guard" do
    before { allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(12) }

    it "redirects signed-in users without a selected profile to /profiles/select" do
      sign_in user

      get "/"

      expect(response).to redirect_to("/profiles/select")
    end

    it "keeps the selected profile id in session after a valid selection" do
      sign_in user
      post "/session/select-profile", params: { profile_id: profile.id }

      expect(response).to have_http_status(:ok)
      expect(session[:current_profile_id]).to eq(profile.id)
      expect(session[:profile_last_activity_at]).to be_present
    end
  end

  describe "POST /api/v1/auth/refresh" do
    before { allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(12) }

    it "copies profile selection and activity to the new token" do
      old_activity = 1.hour.ago
      token = create_token(profile_id: profile.id, last_activity: old_activity)

      post "/api/v1/auth/refresh", params: { refresh_token: token.refresh_token }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      new_token = Doorkeeper::AccessToken.find_by(token: body["access_token"])
      expect(new_token.current_profile_id).to eq(profile.id)
      expect(new_token.profile_last_activity_at).to be_present
    end
  end
end
