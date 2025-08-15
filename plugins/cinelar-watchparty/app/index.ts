import { useSiteSettings } from "@/app/services/site-settings";
import { registerPluginOutlet } from "@/components/PluginOutlet";
import { usePluginOutlets } from "@/stores/pluginOutlets";
import { defineAsyncComponent, defineComponent, h } from "vue";
import WatchPartyChat from "./assets/javascripts/components/WatchPartyChat";



export default {
    name: 'CinelarWatchPartyPlugin',
    version: '1.0.0',
    description: 'Plugin para integrar la funcionalidad de Watch Party en CinelarTV',
    init() {

        const { siteSettings } = useSiteSettings();

        if (!siteSettings.cinelar_watchparty_enabled) {
            console.warn('Cinelar Watch Party plugin is disabled in site settings.');
            return;
        }
        registerPluginOutlet('player:top-controls:right', defineAsyncComponent(() => import('./assets/javascripts/components/WatchPartyToggle')));
        registerPluginOutlet('player:after-media-player', WatchPartyChat)

    }
};