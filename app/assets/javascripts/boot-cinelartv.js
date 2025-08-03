import { showPreloaderError } from './cinelartv/pre-initializers/essentials-preload';
import '@/application.css';
import loadScript from './cinelartv/lib/load-script.js';
import { SafeMode } from './cinelartv/pre-initializers/safe-mode.js';
import { useSiteSettings } from "./cinelartv/app/services/site-settings.ts";
import { PiniaStore } from "./cinelartv/app/lib/Pinia.ts";

const { siteSettings } = useSiteSettings();


import(/* webpackChunkName: "cinelartv" */ './cinelartv/application.js').then(async module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    document.querySelector("noscript")?.remove();
    window.CinelarTV = CinelarTV;

    try {
        // Carga PluginAPI de forma dinámica
        const pluginApiModule = await import('./cinelartv/lib/PluginAPI.ts');
        window.PluginAPI = new pluginApiModule.default('1.0.0', CinelarTV);

        if (SafeMode.enabled) {
            window.PluginAPI.addGlobalNotice({
                id: 'safe-mode',
                type: 'warning',
                content: 'The site is running in safe mode. Some features may be disabled.',
                show: true,
            });
        }
    } catch (error) {
        console.error('Error loading PluginAPI:', error);
    }

    try {
        // Carga JS personalizado si está definido
        if (siteSettings.custom_js && siteSettings.custom_js.length > 0) {
            console.log('Loading custom JavaScript');
            loadScript(null, siteSettings.custom_js);
        }
    } catch (error) {
        console.error('Error loading custom JS:', error);
    }

}).catch(error => {
    console.error(error);
    showPreloaderError(error);
    throw `CinelarTV failed to load: ${error}`;
});
