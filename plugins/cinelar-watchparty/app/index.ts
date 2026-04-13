import { useSiteSettings } from "@/app/services/site-settings";
import { registerPluginOutlet } from "@/components/PluginOutlet";
import { usePluginOutlets } from "@/stores/pluginOutlets";
import { defineAsyncComponent, defineComponent, h, ref, provide } from "vue";
import WatchPartyChat from "./assets/javascripts/components/WatchPartyChat";
import { useWatchParty } from "./assets/javascripts/services/watchparty-service";

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

        // Create shared WatchParty service instance
        const watchpartyService = useWatchParty();
        provide('watchparty', watchpartyService);

        // Register toggle button in player top controls
        registerPluginOutlet(
            'player:top-controls:right',
            defineAsyncComponent(() => import('./assets/javascripts/components/WatchPartyToggle'))
        );

        // Register chat panel after media player
        registerPluginOutlet(
            'player:after-media-player',
            WatchPartyChat
        );

        console.log('Cinelar Watch Party plugin initialized successfully');
    }
};
