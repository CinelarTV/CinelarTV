// Carga dinámica de plugins (excluyendo archivos .route.js)
// Similar a la lógica de router-map.js

const loadPlugins = async () => {
    console.log('🔌 Buscando plugins para cargar...');
    // Vite glob: buscar entry points en dos ubicaciones comunes
    // 1. plugins/[nombre]/index.ts
    // 2. plugins/[nombre]/app/index.ts
    // @ts-ignore
    const globPattern1 = (import.meta as any).glob('@plugins/*/index.ts', { eager: false });
    // @ts-ignore
    const globPattern2 = (import.meta as any).glob('@plugins/*/app/index.ts', { eager: false });

    // Combinar ambos globs
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

    // Fase 2: Inicializar todos en paralelo (sin romper si alguno falla)
    if (pluginsToInit.length > 0) {
        const initPromises = pluginsToInit.map(({ path, plugin }) =>
            Promise.resolve().then(() => {
                plugin.init();
                console.log(`🚀 Plugin inicializado: ${plugin.name}`);
            }).catch((e) => {
                console.error(`❌ Error al inicializar plugin ${plugin.name} (${path}):`, e);
                // No re-throw: continuamos con otros plugins
            })
        );

        await Promise.all(initPromises); // Seguro: catch individual previene rechazos
    }

    console.log(`📦 Total plugins cargados: ${loadedPlugins.length}`);
    return loadedPlugins;
};

export default loadPlugins;
