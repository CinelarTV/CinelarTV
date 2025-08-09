
import loadScript from '../webclient/lib/load-script.js';
//import { SafeMode } from '../cinelartv-legacy/pre-initializers/safe-mode.js';
import { useSiteSettings } from "../webclient/app/services/site-settings.js";
import { PiniaStore } from "../webclient/app/lib/Pinia.js";
//import { showPreloaderError } from "../ pre-initializers/essentials-preload.js";



import(/* webpackChunkName: "cinelartv" */ '../webclient/application.js').then(async module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    document.querySelector("noscript")?.remove();
    window.CinelarTV = CinelarTV;

    try {

        const { siteSettings } = useSiteSettings();

        // Carga PluginAPI de forma dinámica
        const pluginApiModule = await import('../webclient/lib/PluginAPI.js');
        window.PluginAPI = new pluginApiModule.default('1.0.0', CinelarTV);

        /*  if (SafeMode.enabled) {
             window.PluginAPI.addGlobalNotice({
                 id: 'safe-mode',
                 type: 'warning',
                 content: 'The site is running in safe mode. Some features may be disabled.',
                 show: true,
             });
         } */

        try {
            // Carga JS personalizado si está definido
            if (siteSettings.custom_js && siteSettings.custom_js.length > 0) {
                console.log('Loading custom JavaScript');
                loadScript(null, siteSettings.custom_js);
            }
        } catch (error) {
            console.error('Error loading custom JS:', error);
        }
    } catch (error) {
        console.error('Error loading PluginAPI:', error);
    }



}).catch(error => {
    console.error(error);
    // showPreloaderError(error);
    throw `CinelarTV failed to load: ${error}`;
});
