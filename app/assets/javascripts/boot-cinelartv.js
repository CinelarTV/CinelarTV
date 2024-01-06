import { showPreloaderError } from './cinelartv/pre-initializers/essentials-preload';
import '../builds/cinelartv-wind.css'
import loadScript from './cinelartv/lib/load-script';
import { SafeMode } from './cinelartv/pre-initializers/safe-mode';
import { useSiteSettings } from "./cinelartv/app/services/site-settings.ts";
import { PiniaStore } from "./cinelartv/app/lib/Pinia.ts";

const { siteSettings } = useSiteSettings();


import(/* webpackChunkName: "cinelartv" */ './cinelartv/application').then(module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    /* Remove noscript tag on load */
    document.querySelector("noscript")?.remove();
    /* Make CinelarTV available globally */
    window.CinelarTV = CinelarTV;

    try {
        // Load the plugin API after CinelarTV is mounted (to ensure the global store is available)
        const PluginAPI = require('./cinelartv/lib/PluginAPI.ts').default;
        window.PluginAPI = new PluginAPI('1.0.0', CinelarTV);

        if (SafeMode.enabled) {
            window.PluginAPI.addGlobalNotice({
                id: 'safe-mode',
                type: 'warning',
                content: 'The site is running in safe mode. Some features may be disabled.',
                show: true,
            })
        }
    } catch (error) {
        console.log(error);
    }

    try {
        // Load custom JavaScript after CinelarTV is mounted
        if (siteSettings.custom_js && siteSettings.custom_js.length > 0) {
            console.log('Loading custom JavaScript');
            loadScript(null, siteSettings.custom_js);
        }
    } catch (error) {

    }

}).catch(error => {
    console.log(error);
    showPreloaderError(error);
    throw `CinelarTV failed to load: ${error}`;
});
