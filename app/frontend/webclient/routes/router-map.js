import { createWebHistory, createRouter } from 'vue-router'

import CinelarTV from '../application'
import { SafeMode } from '../pre-initializers/safe-mode.ts'
import { useSiteSettings } from '../app/services/site-settings'
import { useCurrentUser } from '../app/services/current-user'
import { PiniaStore } from '../app/lib/Pinia'

const { siteSettings } = useSiteSettings(PiniaStore)

const loadRoutes = () => {
    console.log('🔄 Cargando rutas principales...');
    const modules = import.meta.glob('./**/*.route.js', { eager: true });
    const routes = Object.entries(modules)
        .map(([path, module]) => {
            if (!module.default?.path) {
                console.warn(`⚠️ Ruta ${module.default?.name || 'sin nombre'} no tiene path. Saltando...`);
                return null;
            }
            console.log(`✅ Ruta cargada: ${module.default.name} -> ${module.default.path}`);
            return module.default;
        })
        .filter(Boolean);

    console.log(`📊 Total rutas principales cargadas: ${routes.length}`);
    return routes;
}

const getAvailablePlugins = () => {
    // Usar cualquier archivo para detectar plugins
    const allPluginFiles = import.meta.glob('@plugins/**/*', { eager: false });

    const plugins = [...new Set(
        Object.keys(allPluginFiles)
            .map(path => {
                const match = path.match(/@plugins\/([^\/]+)/);
                return match ? match[1] : null;
            })
            .filter(Boolean)
    )];

    console.log('🔍 Plugins detectados:', plugins);
    return plugins;
}

const loadPluginRoutes = () => {
    console.log('🔌 Iniciando carga de rutas de plugins...');

    const plugins = getAvailablePlugins();
    console.log(`🔌 Plugins habilitados: ${plugins.join(', ')}`);

    try {
        // Un solo patrón que capture todas las rutas de plugins
        const allPluginModules = import.meta.glob('@plugins/**/*.route.js', { eager: true });

        console.log('📦 Archivos de rutas encontrados:', Object.keys(allPluginModules));

        if (Object.keys(allPluginModules).length === 0) {
            console.log('❌ No se encontraron archivos .route.js en plugins');
            return [];
        }

        const routes = Object.entries(allPluginModules)
            .map(([path, module]) => {
                if (!module.default?.path) {
                    console.warn(`⚠️ Archivo ${path} no exporta una ruta válida`);
                    return null;
                }

                // Extraer nombre del plugin del path (soporta rutas relativas y absolutas)
                let pluginName = module.default?.meta?.plugin;
                if (!pluginName) {
                    // Busca /plugins/ o @plugins/ y toma el siguiente segmento
                    const match = path.match(/[\\/@]plugins[\\/](.*?)[\\/]/i);
                    pluginName = match ? match[1] : 'unknown';
                }

                console.log(`✅ Ruta cargada [${pluginName}]: ${module.default.name || 'sin nombre'} -> ${module.default.path}`);

                return {
                    ...module.default,
                    meta: {
                        ...module.default.meta,
                        plugin: pluginName
                    }
                };
            })
            .filter(Boolean);

        // Remover duplicados por path
        const uniqueRoutes = routes.filter((route, index, self) =>
            index === self.findIndex(r => r.path === route.path)
        );

        if (uniqueRoutes.length !== routes.length) {
            console.warn(`⚠️ Se removieron ${routes.length - uniqueRoutes.length} rutas duplicadas`);
        }

        console.log(`📊 Total rutas de plugins cargadas: ${uniqueRoutes.length}`);

        // Mostrar resumen por plugin
        const pluginSummary = uniqueRoutes.reduce((acc, route) => {
            const plugin = route.meta.plugin || ''
            acc[plugin] = (acc[plugin] || 0) + 1;
            return acc;
        }, {});

        console.log('📋 Rutas por plugin:', pluginSummary);

        return uniqueRoutes;

    } catch (error) {
        console.error('❌ Error cargando rutas de plugins:', error);
        return [];
    }
}

const processPluginModules = (modules, patternName) => {
    const foundRoutes = Object.keys(modules);

    if (foundRoutes.length > 0) {
        console.log(`📦 Encontradas ${foundRoutes.length} rutas con ${patternName}:`);
        foundRoutes.forEach(route => console.log(`  - ${route}`));

        return Object.entries(modules)
            .map(([path, module]) => {
                if (!module.default?.path) {
                    console.warn(`⚠️ Plugin ruta ${module.default?.name || path} no tiene path. Saltando...`);
                    return null;
                }

                // Extraer nombre del plugin desde la ruta
                const pluginMatch = path.match(/@plugins\/([^\/]+)/);
                const pluginName = pluginMatch ? pluginMatch[1] : 'unknown';

                console.log(`✅ Plugin ruta cargada [${pluginName}]: ${module.default.name} -> ${module.default.path}`);

                return {
                    ...module.default,
                    meta: {
                        ...module.default.meta,
                        plugin: pluginName
                    }
                };
            })
            .filter(Boolean);
    }

    return [];
}

const initializeRoutes = () => {
    console.log('🚀 Inicializando sistema de rutas...');

    let routes = loadRoutes();

    // Cargar plugins si están habilitados
    if (siteSettings.enable_plugins) {
        console.log('🔌 Plugins habilitados en configuración');

        if (SafeMode.enabled && SafeMode.noPlugins) {
            console.log('🔒 Modo seguro activado - plugins deshabilitados');
        } else {
            console.log('✅ Cargando rutas de plugins...');
            const pluginRoutes = loadPluginRoutes();
            routes = routes.concat(pluginRoutes);
        }
    } else {
        console.log('❌ Plugins deshabilitados en configuración');
    }

    console.log(`📊 Total rutas registradas: ${routes.length}`);

    // Mostrar resumen de rutas
    const routeSummary = routes.reduce((acc, route) => {
        const source = route.meta?.plugin ? `plugin:${route.meta.plugin}` : 'core';
        acc[source] = (acc[source] || 0) + 1;
        return acc;
    }, {});

    console.log('📋 Resumen de rutas por fuente:', routeSummary);

    return routes;
}

// Inicializar rutas
const routes = initializeRoutes();

const AppRouter = createRouter({
    history: createWebHistory(),
    routes
});

AppRouter.beforeEach((to, from, next) => {
    const { currentUser } = useCurrentUser();
    document.body.classList.add('route-transition');

    // Enlaces externos: abrir en nueva pestaña y cancelar navegación
    if (/^https?:\/\//.test(to.path)) {
        window.open(to.path, '_blank');
        next(false);
        return;
    }

    // Redirigir a home si ya tiene perfil
    if (to.name === 'profile.select' && currentUser?.current_profile) {
        next({ name: 'home.index', replace: true });
        return;
    }

    // Permitir acceso a selección de perfil si no tiene perfil
    if (to.name === 'profile.select' && currentUser && !currentUser.current_profile) {
        next();
        return;
    }

    // Requiere auth y no hay usuario
    if (to.meta.requiresAuth && !currentUser) {
        next({ name: 'NotFound', replace: true });
        return;
    }

    // Requiere perfil y no lo tiene (excepto wizard)
    if (currentUser && !currentUser.current_profile && !['application.wizard', 'wizard.step', 'profile.select'].includes(String(to.name))) {
        next({ name: 'profile.select', replace: true });
        return;
    }

    // Requiere admin y no es admin
    if (to.meta.requireAdmin && (!currentUser || !currentUser.admin)) {
        next({ name: 'NotFound', replace: true });
        return;
    }

    // Rutas de login/signup: redirigir a home y mostrar modal
    if (to.path === '/login' || to.path === '/signup') {
        next({ name: 'home.index', replace: true });
        return;
    }

    // Log de navegación para rutas de plugins
    if (to.meta?.plugin) {
        console.log(`🔌 Navegando a ruta de plugin [${to.meta.plugin}]: ${to.path}`);
    }

    // Permite la navegación normal
    next();
    CinelarTV.config.globalProperties.$progress.finish();
});

AppRouter.afterEach((to, from) => {
    if (window.MiniProfiler && from) {
        window.MiniProfiler.pageTransition();
    }
    document.body.setAttribute('data-current-path', to.path);
    CinelarTV.config.globalProperties.$progress.finish();
    document.body.classList.remove('route-transition');
});

AppRouter.onError((err) => {
    if (/loading chunk \d* failed./i.test(err.message)) {
        if (confirm(window.I18n.t('js.errors.chunk_loading_error'))) {
            window.location.reload();
        }
    }
});

window.AppRouter = AppRouter;

export default AppRouter;