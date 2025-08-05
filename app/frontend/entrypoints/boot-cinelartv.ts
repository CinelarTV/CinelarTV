
import loadScript from '../cinelartv-legacy/lib/load-script.js';
//import { SafeMode } from '../cinelartv-legacy/pre-initializers/safe-mode.js';
import { useSiteSettings } from "../cinelartv-legacy/app/services/site-settings";
import { PiniaStore } from "../cinelartv-legacy/app/lib/Pinia";
//import { showPreloaderError } from "../ pre-initializers/essentials-preload.js";



import(/* webpackChunkName: "cinelartv" */ '../cinelartv-legacy/application.js').then(async module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    document.querySelector("noscript")?.remove();
    window.CinelarTV = CinelarTV;

    try {

        const { siteSettings } = useSiteSettings();

        // Carga PluginAPI de forma dinámica
        const pluginApiModule = await import('../cinelartv-legacy/lib/PluginAPI');
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
