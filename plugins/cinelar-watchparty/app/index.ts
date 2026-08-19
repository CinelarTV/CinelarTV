import { useSiteSettings } from "@cinelartv/core";
import { definePlugin } from "@cinelartv/plugin-api";
import { defineAsyncComponent } from "vue";
import WatchPartyChat from "./assets/javascripts/components/WatchPartyChat";
import { useWatchParty } from "./assets/javascripts/services/watchparty-service";
import "./assets/styles/watchparty.css";

export default definePlugin({
  id: "cinelar-watchparty",
  setup(api) {
    const { siteSettings } = useSiteSettings();
    if (!siteSettings.cinelar_watchparty_enabled) return;

    useWatchParty();
    api.outlets.register("player.topControls.right", {
      id: "toggle",
      component: defineAsyncComponent(() => import("./assets/javascripts/components/WatchPartyToggle")),
    });
    api.outlets.register("player.afterMedia", { id: "chat", component: WatchPartyChat });
  },
});
