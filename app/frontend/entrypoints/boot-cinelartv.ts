
import loadScript from '../webclient/lib/load-script.js';
//import { SafeMode } from '../cinelartv-legacy/pre-initializers/safe-mode.js';
import { useSiteSettings } from "../webclient/app/services/site-settings.js";
import { PiniaStore } from "../webclient/app/lib/Pinia.js";
import { showPreloaderError } from "@/pre-initializers/essentials-preload.js";
//import { showPreloaderError } from "../ pre-initializers/essentials-preload.js";



import(/* webpackChunkName: "cinelartv" */ '../webclient/application.js').then(async module => {
    const CinelarTV = module.default;
    const { loadPlugins } = module;

    // Mount app
    CinelarTV.mount('#cinelartv');
    document.querySelector("noscript")?.remove();
    window.CinelarTV = CinelarTV;

    try {
        const { siteSettings } = useSiteSettings();

        // Ejecutar en paralelo: loadPlugins + PluginAPI + custom_js
        const [, pluginApiModule] = await Promise.all([
            // Fase 1: plugins (el más lento usualmente)
            loadPlugins().catch(e => {
                console.error('❌ Error cargando plugins:', e);
                return []; // Continuar aunque fallen plugins
            }),

            // Fase 2: PluginAPI
            import('../webclient/lib/PluginAPI.js').catch(e => {
                console.error('❌ Error cargando PluginAPI:', e);
                return { default: null };
            })
        ]);

        // Inicializar PluginAPI si se cargó correctamente
        if (pluginApiModule?.default) {
            window.PluginAPI = new pluginApiModule.default('1.0.0', CinelarTV);
        } else {
            console.warn('⚠️ PluginAPI no está disponible');
        }



        // Fase 3: Custom JS (no bloquea, pero después de PluginAPI listo)
        try {
            if (siteSettings.custom_js && siteSettings.custom_js.length > 0) {
                console.log('🔧 Loading custom JavaScript');
                await loadScript(null, siteSettings.custom_js);
            }
        } catch (error) {
            console.error('❌ Error loading custom JS:', error);
        }
    } catch (error) {
        console.error('❌ Error en boot flow:', error);
    }



}).catch(error => {
    console.error(error);
    showPreloaderError(error);
    throw `CinelarTV failed to load: ${error}`;
});
