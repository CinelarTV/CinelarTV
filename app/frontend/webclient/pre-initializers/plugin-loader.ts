// Source-plugin discovery adapter. Compiled third-party plugins are loaded by
// PluginHost from the server registry; this remains for workspace plugins while
// they migrate to independently compiled artifacts.
const loadPlugins = async () => {
    const modules = {
        // @ts-ignore Vite glob aliases are resolved at build time.
        ...(import.meta as any).glob('@plugins/*/index.ts', { eager: false }),
        // @ts-ignore
        ...(import.meta as any).glob('@plugins/*/app/index.ts', { eager: false }),
    };
    const loadedPlugins: Array<{ path: string; plugin: any }> = [];

    for (const [path, loader] of Object.entries(modules)) {
        try {
            const mod = await (typeof loader === 'function' ? (loader as any)() : loader as any);
            if (mod?.default) loadedPlugins.push({ path, plugin: mod.default });
        } catch (error) {
            console.error(`[PluginLoader] failed to discover ${path}`, error);
        }
    }

    // Convention connectors are a legacy adapter. New plugins use the public
    // outlets API, which supplies ownership, priority and cleanup.
    const connectors = (import.meta as any).glob('@plugins/*/assets/javascripts/connectors/**/*.{vue,tsx}', { eager: true });
    const { registerPluginOutlet } = await import('@/components/PluginOutlet');
    for (const [path, mod] of Object.entries(connectors)) {
        const outlet = path.match(/connectors\/([^/]+)\//)?.[1];
        if (outlet && (mod as any).default) registerPluginOutlet(outlet, (mod as any).default);
    }

    return loadedPlugins;
};

export default loadPlugins;
