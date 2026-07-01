# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  describe "GET /sitemap.xml" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
        Rails.cache.clear
      end

      it "responds with success" do
        get "/sitemap.xml"
        expect(response).to have_http_status(:success)
      end

      it "renders an XML response" do
        get "/sitemap.xml"
        expect(response.content_type).to include("application/xml")
      end

      it "returns sitemap index with sub-sitemaps" do
        get "/sitemap.xml"
        xml = Nokogiri::XML(response.body)
        xml.remove_namespaces!
        expect(xml.css("sitemapindex sitemap").size).to eq(2)
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get "/sitemap.xml"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /sitemap-contents.xml" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
        Rails.cache.clear
      end

      it "responds with success" do
        get "/sitemap-contents.xml"
        expect(response).to have_http_status(:success)
      end

      it "renders an XML response" do
        get "/sitemap-contents.xml"
        expect(response.content_type).to include("application/xml")
      end

      it "includes url entries for each content" do
        create(:content, title: "Test Content")

        get "/sitemap-contents.xml"
        xml = Nokogiri::XML(response.body)
        xml.remove_namespaces!
        expect(xml.css("urlset url").size).to be >= 1
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get "/sitemap-contents.xml"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /sitemap-episodes.xml" do
    context "when sitemap is enabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
        Rails.cache.clear
      end

      it "responds with success" do
        get "/sitemap-episodes.xml"
        expect(response).to have_http_status(:success)
      end

      it "renders an XML response" do
        get "/sitemap-episodes.xml"
        expect(response.content_type).to include("application/xml")
      end

      it "includes episodes in the sitemap" do
        content = create(:content, title: "Test Show")
        season = create(:season, content: content)
        create(:episode, season: season, title: "Pilot")

        get "/sitemap-episodes.xml"
        xml = Nokogiri::XML(response.body)
        xml.remove_namespaces!
        expect(xml.css("urlset url").size).to be >= 1
      end
    end

    context "when sitemap is disabled" do
      before do
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
        allow(SiteSetting).to receive(:waiting_on_first_user).and_return(false)
      end

      it "responds with not_found" do
        get "/sitemap-episodes.xml"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
