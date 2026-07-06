
import loadScript from '../webclient/lib/load-script.js';
//import { SafeMode } from '../cinelartv-legacy/pre-initializers/safe-mode.js';
import { useSiteSettings } from "../webclient/app/services/site-settings.js";
import { PiniaStore } from "../webclient/app/lib/Pinia.js";
import { showPreloaderError } from "@/pre-initializers/essentials-preload.js";
//import { showPreloaderError } from "../ pre-initializers/essentials-preload.js";



import(/* webpackChunkName: "cinelartv" */ '../webclient/application.js').then(async module => {
    const CinelarTV = module.default;
    const { loadPlugins } = module;

    // Iniciar carga de plugins en paralelo ANTES de montar la app
    const pluginsPromise = loadPlugins().catch(e => {
        console.error('❌ Error cargando plugins:', e);
        return []; // Continuar aunque fallen plugins
    });

    const pluginApiPromise = import('../webclient/lib/PluginAPI.js').catch(e => {
        console.error('❌ Error cargando PluginAPI:', e);
        return { default: null };
    });

    // Mount app inmediatamente mientras los plugins cargan en background
    console.log('🚀 Mounting CinelarTV app...');
    CinelarTV.mount('#cinelartv');
    document.querySelector("noscript")?.remove();
    window.CinelarTV = CinelarTV;

    // Core modules (Vue, Pinia, etc.) are already on window.CinelarTV
    // via plugin-core.ts which loads before this entry point.

    try {
        const { siteSettings } = useSiteSettings();

        // Esperar a que terminen las cargas paralelas
        const [plugins, pluginApiModule] = await Promise.all([
            pluginsPromise,
            pluginApiPromise
        ]);

        // Inicializar PluginAPI si se cargó correctamente
        if (pluginApiModule?.default) {
            window.PluginAPI = new pluginApiModule.default('1.0.0', CinelarTV);
            console.log('✅ PluginAPI initialized');
        } else {
            console.warn('⚠️ PluginAPI no está disponible');
        }

        console.log(`📦 Plugins loaded: ${plugins.length}`);

        // Custom JS (no bloquea, pero después de PluginAPI listo)
        if (siteSettings.custom_js && siteSettings.custom_js.length > 0) {
            console.log('🔧 Loading custom JavaScript');
            loadScript(null, siteSettings.custom_js).catch(error => {
                console.error('❌ Error loading custom JS:', error);
            });
        }

        console.log('🎉 CinelarTV boot completed successfully');
    } catch (error) {
        console.error('❌ Error en boot flow:', error);
    }

}).catch(error => {
    console.error(error);
    showPreloaderError(error);
    throw `CinelarTV failed to load: ${error}`;
});
