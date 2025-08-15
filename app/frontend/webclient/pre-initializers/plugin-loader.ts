// Carga dinámica de plugins (excluyendo archivos .route.js)
// Similar a la lógica de router-map.js

const loadPlugins = async () => {
    console.log('🔌 Buscando plugins para cargar...');
    // Buscar todos los JS/TS/MJS en @plugins, excepto *.route.js/ts/mjs
    // @ts-ignore
    const pluginModules = (import.meta as any).glob('@plugins/**/*.{js,ts,mjs}', { eager: false });
    // Filtrar los que NO terminan en .route.js/.route.ts/.route.mjs
    const filteredEntries = Object.entries(pluginModules).filter(([path]) => !/\.route\.(js|ts|mjs)$/.test(path));

    if (filteredEntries.length === 0) {
        console.log('❌ No se encontraron plugins para cargar');
        return [];
    }

    const loadedPlugins = [];
    for (const [path, loader] of filteredEntries) {
        try {
            // @ts-ignore
            const mod = await (typeof loader === 'function' ? loader() : loader);
            if (mod && mod.default) {
                const plugin = mod.default;
                loadedPlugins.push({ path, plugin });
                console.log(`✅ Plugin cargado: ${path}`);
                if (typeof plugin.init === 'function' && typeof plugin.name === 'string') {
                    try {
                        plugin.init();
                        console.log(`🚀 Plugin inicializado: ${plugin.name}`);
                    } catch (e) {
                        console.error(`❌ Error al inicializar plugin ${plugin.name}:`, e);
                    }
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
    console.log(`📦 Total plugins cargados: ${loadedPlugins.length}`);
    return loadedPlugins;
};

export default loadPlugins;
