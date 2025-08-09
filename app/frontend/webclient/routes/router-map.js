import { createWebHistory, createRouter } from 'vue-router'
import { query } from '../utils/query'
import CinelarTV from '../application'
//import { SafeMode } from '../pre-initializers/safe-mode'
import { useSiteSettings } from '../app/services/site-settings'
import { useCurrentUser } from '../app/services/current-user'
import { PiniaStore } from '../app/lib/Pinia'

const { siteSettings } = useSiteSettings(PiniaStore)


const loadRoutes = () => {
    // Carga todos los archivos .route.js en el directorio actual y subdirectorios
    const modules = import.meta.glob('./**/*.route.js', { eager: true });
    return Object.values(modules)
        .map(m => {
            if (!m.default?.path) {
                console.warn(`Route ${m.default?.name} has no path. Skipping...`)
                return;
            }
            return m.default;
        })
        .filter(Boolean);
}

const loadPluginRoutes = () => {
    // Ajusta la ruta según la estructura real de tus plugins
    const modules = import.meta.glob('/plugins/cinelar-watchparty/**/routes/*.route.js', { eager: true });
    return Object.values(modules)
        .map(m => {
            if (!m.default?.path) {
                console.warn(`Route ${m.default?.name} has no path. Skipping...`)
                return;
            }
            return m.default;
        })
        .filter(Boolean);
}



let routes = []

routes = routes.concat(loadRoutes())

/* if (siteSettings.enable_plugins) {
    if (SafeMode.enabled && SafeMode.noPlugins) { }
    else {
        routes = routes.concat(loadPluginRoutes())
    }

}
 */


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