import { showPreloaderError } from './cinelartv/pre-initializers/essentials-preload';
import '../builds/cinelartv-wind.css'


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
        window.PluginAPI = new PluginAPI('1.0.0');
    } catch (error) {
        
    }

}).catch(error => {
    console.log(error);
    showPreloaderError();
    throw "Unable to boot CinelarTV: Essential preloaded data not found";
});
