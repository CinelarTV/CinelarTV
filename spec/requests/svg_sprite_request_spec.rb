# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SvgSprite", type: :request do
  before do
    Rails.cache.clear
    SvgSprite.instance_variable_set(:@plugin_svg_files, nil)
    allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
  end

  describe "GET /svg-sprite.svg" do
    context "when experimental_icon_engine is enabled" do
      before do
        allow(SiteSetting).to receive(:experimental_icon_engine).and_return(true)
      end

      it "returns success" do
        get "/svg-sprite.svg"
        expect(response).to have_http_status(:success)
      end

      it "returns SVG content type" do
        get "/svg-sprite.svg"
        expect(response.content_type).to include("image/svg+xml")
      end

      it "returns a valid SVG sprite" do
        get "/svg-sprite.svg"
        expect(response.body).to start_with("<svg xmlns='http://www.w3.org/2000/svg'")
        expect(response.body).to include("<symbol id=\"play\"")
        expect(response.body).to end_with("</svg>")
      end

      it "includes ETag header" do
        get "/svg-sprite.svg"
        expect(response.headers["ETag"]).to be_present
      end

      it "returns 304 when ETag matches" do
        get "/svg-sprite.svg"
        etag = response.headers["ETag"]

        get "/svg-sprite.svg", headers: { "If-None-Match" => etag }
        expect(response).to have_http_status(:not_modified)
      end
    end

    context "when experimental_icon_engine is disabled" do
      before do
        allow(SiteSetting).to receive(:experimental_icon_engine).and_return(false)
      end

      it "returns 404" do
        get "/svg-sprite.svg"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /admin/icon-picker/search" do
    let(:admin_user) { create(:user) }

    before do
      admin_user.add_role(:admin)
      sign_in admin_user
      allow(SiteSetting).to receive(:experimental_icon_engine).and_return(true)
    end

    it "returns icon list" do
      get "/admin/icon-picker/search"
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first).to have_key("id")
    end

    it "filters by keyword" do
      get "/admin/icon-picker/search", params: { filter: "play" }
      json = JSON.parse(response.body)
      ids = json.map { |i| i["id"] }
      expect(ids).to all(include("play"))
    end
  end
end
