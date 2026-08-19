import loadScript from '../webclient/lib/load-script.js';
import { useSiteSettings } from "../webclient/app/services/site-settings.js";
import { showPreloaderError } from "@/pre-initializers/essentials-preload.js";
import { createPluginHost } from "../webclient/plugins/PluginHost";

import('../webclient/application.js').then(async module => {
    const CinelarTV = module.default;
    const { loadPlugins } = module;

    // Discovery may happen early, but PluginHost initialization deliberately
    // waits until the app and the legacy API are both available.
    const pluginsPromise = loadPlugins().catch((error: unknown) => {
        console.error('[CinelarTV] plugin discovery failed', error);
        return [];
    });
    const pluginApiPromise = import('../webclient/lib/PluginAPI.js').catch(() => ({ default: null }));

    CinelarTV.mount('#cinelartv');
    document.querySelector('noscript')?.remove();
    (window as any).CinelarTV = CinelarTV;

    try {
        const { siteSettings } = useSiteSettings();
        const [plugins, pluginApiModule] = await Promise.all([pluginsPromise, pluginApiPromise]);
        if (pluginApiModule?.default) (window as any).PluginAPI = new pluginApiModule.default('1.0.0', CinelarTV);

        const host = createPluginHost((window as any).__CINELARTV_PLUGIN_BOOTSTRAP__?.plugins || []);
        (window as any).CinelarTVPluginHost = host;
        for (const { path, plugin } of plugins as any[]) {
            const id = plugin.id || plugin.name || path.match(/@plugins\/([^/]+)/)?.[1];
            if (!id) continue;
            try {
                await host.initializeDefinition(id, plugin);
            } catch (error) {
                console.error(`[CinelarTV] failed to initialize plugin ${id}`, error);
            }
        }
        await host.initialize();

        if (siteSettings.custom_js?.length) loadScript(null, siteSettings.custom_js).catch(console.error);
    } catch (error) {
        console.error('[CinelarTV] boot failed', error);
    }
}).catch(error => {
    console.error(error);
    showPreloaderError(error);
    throw new Error(`CinelarTV failed to load: ${error}`);
});
