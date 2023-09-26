import { SiteSettings, showPreloaderError } from './cinelartv/pre-initializers/essentials-preload';
import '../builds/cinelartv-wind.css'
import loadScript from './cinelartv/lib/load-script';
import { SafeMode } from './cinelartv/pre-initializers/safe-mode';


import(/* webpackChunkName: "cinelartv" */ './cinelartv/application').then(module => {
    const CinelarTV = module.default;
    CinelarTV.mount('#cinelartv');
    /* Remove noscript tag on load */
    document.querySelector("noscript")?.remove();
    /* Make CinelarTV available globally */
    window.CinelarTV = CinelarTV;

    try {
        // Load the plugin API after CinelarTV is mounted (to ensure the global store is available)
        const PluginAPI = require('./cinelartv/lib/plugin-api').default;
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
        if (SiteSettings.custom_js && SiteSettings.custom_js.length > 0) {
            loadScript(null, SiteSettings.custom_js);
        }
    } catch (error) {

    }

}).catch(error => {
    console.log(error);
    showPreloaderError();
    throw "Unable to boot CinelarTV: Essential preloaded data not found";
});
