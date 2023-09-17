# frozen_string_literal: true

# spec/controllers/likes_controller_spec.rb

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe LikesController, type: :controller do
  let(:user) { create(:user) }
  let(:content) { create(:content) }
  # rubocop:disable Style/HashSyntax
  let(:current_profile) { create(:profile, user: user) }

  before do
    sign_in user
  end

  describe "POST #like" do
    it "likes the content" do
      post :like, params: { id: content.id }

      expect(response).to have_http_status(:success)
      expect(user.current_profile.liked_contents).to include(content)
      expect(JSON.parse(response.body)["message"]).to eq("Content liked successfully")
    end

    it "returns an error if already liked" do
      user.current_profile.liked_contents << content

      post :like, params: { id: content.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("You already liked this content")
    end
  end

  describe "DELETE #unlike" do
    it "unlikes the content" do
      user.current_profile.liked_contents << content

      delete :unlike, params: { id: content.id }

      expect(response).to have_http_status(:success)
      expect(user.current_profile.liked_contents).not_to include(content)
      expect(JSON.parse(response.body)["message"]).to eq("Content unliked successfully")
    end

    it "returns an error if you didn't like the content" do
      delete :unlike, params: { id: content.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("You didn't like this content")
    end
  end
end
