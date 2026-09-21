import { definePlugin } from "@cinelartv/plugin-api";
import { registerPluginOutlet } from "@/components/PluginOutlet";
import AdSlot from "./assets/javascripts/components/AdSlot";
import "./assets/styles/ads.css";

const HouseAdsList = () => import("./assets/javascripts/admin/HouseAdsList");
const HouseAdForm = () => import("./assets/javascripts/admin/HouseAdForm");
const HouseAdsSettings = () => import("./assets/javascripts/admin/HouseAdsSettings");
const AdReports = () => import("./assets/javascripts/admin/AdReports");

export default definePlugin({
  id: "cinelar-ads",
  setup(api) {
    registerPluginOutlet("home:before-carousel", {
      id: "cinelar-ads:home-before-carousel",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    registerPluginOutlet("home:after-carousel", {
      id: "cinelar-ads:home-after-carousel",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    registerPluginOutlet("home:between-rows", {
      id: "cinelar-ads:home-between-rows",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    registerPluginOutlet("content:below-actions", {
      id: "cinelar-ads:content-below-actions",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    registerPluginOutlet("content:below-related", {
      id: "cinelar-ads:content-below-related",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    registerPluginOutlet("explore:top", {
      id: "cinelar-ads:explore-top",
      pluginId: "cinelar-ads",
      component: AdSlot,
      priority: 50,
    });

    api.routes.add({
      name: "admin.ads.house-ads",
      path: "ads/house-ads",
      parent: "admin",
      component: HouseAdsList,
      meta: { requireAdmin: true },
    });

    api.routes.add({
      name: "admin.ads.house-ads.new",
      path: "ads/house-ads/new",
      parent: "admin",
      component: HouseAdForm,
      meta: { requireAdmin: true },
    });

    api.routes.add({
      name: "admin.ads.house-ads.edit",
      path: "ads/house-ads/:id/edit",
      parent: "admin",
      component: HouseAdForm,
      meta: { requireAdmin: true },
    });

    api.routes.add({
      name: "admin.ads.settings",
      path: "ads/settings",
      parent: "admin",
      component: HouseAdsSettings,
      meta: { requireAdmin: true },
    });

    api.routes.add({
      name: "admin.ads.reports",
      path: "ads/reports",
      parent: "admin",
      component: AdReports,
      meta: { requireAdmin: true },
    });

    api.admin.addTab({
      label: "Ads",
      icon: "rectangle-ad",
      route: "admin.ads.house-ads",
    });
  },
});
