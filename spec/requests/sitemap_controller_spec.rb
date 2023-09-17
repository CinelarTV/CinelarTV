# spec/controllers/sitemap_controller_spec.rb

require "rails_helper"

RSpec.describe SitemapController, type: :controller do
  describe "GET #index" do
    context "when sitemap is enabled" do
      before do
        # Establece que SiteSetting.enable_sitemap sea verdadero
        allow(SiteSetting).to receive(:enable_sitemap).and_return(true)
      end

      it "responds with success" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "assigns all contents to @contents" do
        # Crea algunos objetos de contenido simulados para la prueba
        content1 = create(:content, title: "Content 1")
        content2 = create(:content, title: "Content 2")

        get :index
        expect(assigns(:contents)).to eq([content1, content2])
      end

      it "renders an XML response" do
        get :index
        expect(response.content_type).to eq("application/xml")
      end
    end

    context "when sitemap is disabled" do
      before do
        # Establece que SiteSetting.enable_sitemap sea falso
        allow(SiteSetting).to receive(:enable_sitemap).and_return(false)
      end

      it "responds with not_found" do
        get :index
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
