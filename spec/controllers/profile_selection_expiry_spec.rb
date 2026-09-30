# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileSelectionExpiry, type: :controller do
  controller(ApplicationController) do
    def index
      last_activity = profile_activity_last_at
      expired = profile_selection_expired?(last_activity)
      profile_id = resolved_profile_id

      render json: {
        profile_id: profile_id,
        expired: expired,
        last_activity: last_activity
      }
    end
  end

  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:profile) { user.profiles.first || create(:profile, user: user) }

  before do
    routes.draw { get "index" => "anonymous#index" }
    allow(SiteSetting).to receive(:profile_selection_timeout_hours).and_return(timeout_hours)
    # Isolate action logic from the ApplicationController before_action
    allow_any_instance_of(ApplicationController).to receive(:touch_profile_activity!)
  end

  describe "when timeout is disabled (0)" do
    let(:timeout_hours) { 0 }

    it "never treats an old activity timestamp as expired" do
      session[:current_profile_id] = profile.id
      session[:profile_last_activity_at] = 30.days.ago

      get :index

      expect(json["profile_id"]).to eq(profile.id)
      expect(json["expired"]).to eq(false)
    end
  end

  describe "when timeout is configured" do
    let(:timeout_hours) { 12 }

    context "with a fresh activity timestamp" do
      it "keeps the selected profile" do
        session[:current_profile_id] = profile.id
        session[:profile_last_activity_at] = 1.hour.ago

        get :index

        expect(json["profile_id"]).to eq(profile.id)
        expect(json["expired"]).to eq(false)
      end
    end

    context "with an expired activity timestamp" do
      it "clears the selection and reports expired" do
        session[:current_profile_id] = profile.id
        session[:profile_last_activity_at] = 13.hours.ago

        get :index

        expect(json["expired"]).to eq(true)
        expect(json["profile_id"]).to be_nil
        expect(session[:current_profile_id]).to be_nil
        expect(session[:profile_last_activity_at]).to be_nil
      end
    end

    context "with a selected profile but no activity timestamp" do
      it "treats it as grace period and keeps the profile" do
        session[:current_profile_id] = profile.id
        session[:profile_last_activity_at] = nil

        get :index

        expect(json["profile_id"]).to eq(profile.id)
        expect(json["expired"]).to eq(false)
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end
