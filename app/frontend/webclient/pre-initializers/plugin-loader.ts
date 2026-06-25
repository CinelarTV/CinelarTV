// Carga dinámica de plugins (excluyendo archivos .route.js)
// Similar a la lógica de router-map.js
// También descubre connectors por naming convention:
//   plugins/*/assets/javascripts/connectors/{outlet-name}/{name}.{vue,tsx}

const loadPlugins = async () => {
    console.log('🔌 Buscando plugins para cargar...');
    // @ts-ignore
    const globPattern1 = (import.meta as any).glob('@plugins/*/index.ts', { eager: false });
    // @ts-ignore
    const globPattern2 = (import.meta as any).glob('@plugins/*/app/index.ts', { eager: false });

    const pluginModules = { ...globPattern1, ...globPattern2 };
    const filteredEntries = Object.entries(pluginModules);

    if (filteredEntries.length === 0) {
        console.log('❌ No se encontraron plugins para cargar');
        return [];
    }

    const loadedPlugins = [];
    const pluginsToInit = [];

    // Fase 1: Cargar todos los módulos de plugins
    for (const [path, loader] of filteredEntries) {
        try {
            // @ts-ignore
            const mod = await (typeof loader === 'function' ? loader() : loader);
            if (mod && mod.default) {
                const plugin = mod.default;
                loadedPlugins.push({ path, plugin });
                console.log(`✅ Plugin cargado: ${path}`);

                if (typeof plugin.init === 'function' && typeof plugin.name === 'string') {
                    pluginsToInit.push({ path, plugin });
                } else {
                    console.warn(`⚠️ Plugin en ${path} no cumple con la estructura mínima (name:string, init:function)`);
                }
            } else {
                console.warn(`⚠️ Plugin ${path} no tiene export default. Saltando...`);
            }
        } catch (err) {
            console.error(`❌ Error cargando plugin ${path}:`, err);
        }
    }

    // Fase 1.5: Descubrir connectors por naming convention
    //   plugins/*/assets/javascripts/connectors/{outlet-name}/{name}.{vue,tsx}
    try {
        // @ts-ignore
        const connectorModules = (import.meta as any).glob(
            '@plugins/*/assets/javascripts/connectors/**/*.{vue,tsx}',
            { eager: true }
        );
        const { registerPluginOutlet } = await import('@/components/PluginOutlet');

        for (const [connectorPath, mod] of Object.entries(connectorModules)) {
            // Extraer outlet name del path: .../connectors/{outlet-name}/{file}
            const match = connectorPath.match(/connectors\/([^\/]+)\//);
            if (!match) continue;

            const outletName = match[1];
            const component = (mod as any).default;
            if (!component) {
                console.warn(`⚠️ Connector ${connectorPath} no tiene default export`);
                continue;
            }

            registerPluginOutlet(outletName, component);
            console.log(`🔌 Connector registrado: ${outletName} <- ${connectorPath}`);
        }
    } catch (err) {
        // Los connectors son opcionales — no romper si no hay
        console.log('ℹ️ No se encontraron connectors (opcional)');
    }

    // Fase 2: Inicializar todos en paralelo
    if (pluginsToInit.length > 0) {
        const initPromises = pluginsToInit.map(({ path, plugin }) =>
            Promise.resolve().then(() => {
                plugin.init();
                console.log(`🚀 Plugin inicializado: ${plugin.name}`);
            }).catch((e) => {
                console.error(`❌ Error al inicializar plugin ${plugin.name} (${path}):`, e);
            })
        );

        await Promise.all(initPromises);
    }

    console.log(`📦 Total plugins cargados: ${loadedPlugins.length}`);
    return loadedPlugins;
};

export default loadPlugins;
