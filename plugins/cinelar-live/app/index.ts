import { definePlugin } from "@cinelartv/plugin-api";
import { registerPluginOutlet } from "@/components/PluginOutlet";
import ScheduleLiveButton from "./assets/javascripts/components/ScheduleLiveButton";
import "./assets/styles/live.css";

export default definePlugin({
  id: "cinelar-live",
  setup(api) {
    registerPluginOutlet("content:actions", {
      id: "cinelar-live:schedule-button",
      pluginId: "cinelar-live",
      component: ScheduleLiveButton,
      when: (ctx: any) => ctx.content?.isMovie,
    });
  },
});
