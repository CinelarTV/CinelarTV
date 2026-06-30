# frozen_string_literal: true

# spec/controllers/sitemap_controller_spec.rb

require "rails_helper"

RSpec.describe SitemapController, type: :controller do
  describe "GET #index" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with success" do
        get :index, format: :xml
        expect(response).to have_http_status(:success)
      end

      it "renders an XML response" do
        get :index, format: :xml
        expect(response.content_type).to include("application/xml")
      end

      it "returns sitemap index with sub-sitemaps" do
        get :index, format: :xml
        xml = Nokogiri::XML(response.body)
        expect(xml.css("sitemapindex sitemap").size).to eq(2)
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get :index, format: :xml
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #contents" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with success" do
        get :contents, format: :xml
        expect(response).to have_http_status(:success)
      end

      it "assigns all available contents to @contents" do
        content1 = create(:content, title: "Content 1")
        content2 = create(:content, title: "Content 2")

        get :contents, format: :xml
        expect(assigns(:contents)).to include(content1, content2)
      end

      it "renders an XML response" do
        get :contents, format: :xml
        expect(response.content_type).to include("application/xml")
      end

      it "includes url entries for each content" do
        create(:content, title: "Test Content")

        get :contents, format: :xml
        xml = Nokogiri::XML(response.body)
        expect(xml.css("urlset url").size).to be >= 1
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get :contents, format: :xml
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #episodes" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with success" do
        get :episodes, format: :xml
        expect(response).to have_http_status(:success)
      end

      it "assigns episodes to @episodes" do
        content = create(:content, title: "Test Show")
        season = create(:season, content: content)
        episode = create(:episode, season: season, title: "Pilot")

        get :episodes, format: :xml
        expect(assigns(:episodes)).to include(episode)
      end

      it "renders an XML response" do
        get :episodes, format: :xml
        expect(response.content_type).to include("application/xml")
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get :episodes, format: :xml
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
