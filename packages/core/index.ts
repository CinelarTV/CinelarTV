// Deliberately curated public core surface. Do not expose `@/` internals here.
export { useSiteSettings } from "../../app/frontend/webclient/app/services/site-settings";
export { useCurrentUser } from "../../app/frontend/webclient/app/services/current-user";
export { pluginEvents } from "../../app/frontend/webclient/lib/plugin-events";
export type { PluginEventMap } from "../../app/frontend/webclient/lib/plugin-events";
