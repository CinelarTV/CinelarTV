import { createWebHistory, createRouter } from 'vue-router'
import { currentUser, SiteSettings } from '../pre-initializers/essentials-preload'
import { success } from 'high-console'
import CinelarTV from '../application'

function loadRoutes() {
    const routes = require.context('./', true, /\.route\.js$/)

    return routes.keys()
        .map(routes)         // import module
        .map(m => {
            return m.default
        })  // get `default` export from each resolved module
}

let routes = loadRoutes()



const AppRouter = createRouter({
    history: createWebHistory(),
    routes
});


AppRouter.beforeEach((to, from, next) => {
   
    // Redirigir a 'home.index' si ya estás en 'profile.select' y el usuario tiene un perfil
    if (to.name === 'profile.select' && currentUser && currentUser.current_profile) {
        next({
            name: 'home.index',
            replace: true
        });
        return
    }

    if (to.name === 'profile.select' && currentUser && !currentUser.current_profile) {
        next();
        return
    }

    // Redirigir a 'NotFound' si se requiere autenticación y no hay usuario
    if (to.meta.requiresAuth && !currentUser) {
        next({
            name: 'NotFound', // Cambia 'NotFound' por la ruta adecuada
            params: [to.path],
            replace: true
        });
        return;
    }

    // Redirigir a 'profile.select' si el usuario no tiene perfil, a menos que la ruta sea wizard
    if (currentUser && !currentUser.current_profile && to.name !== 'application.wizard' && to.name !== 'wizard.step') {
        next({
            name: 'profile.select',
            replace: true
        });
        return;
    }

    // Redirigir a 'NotFound' si se requiere admin y el usuario no es admin
    if (to.meta.requireAdmin && (!currentUser || !currentUser.admin)) {
        next({
            name: 'NotFound', // Cambia 'NotFound' por la ruta adecuada
            params: [to.path],
            replace: true
        });
        return;
    }

    // Catch login and signup routes (They don't exist in the app, we use modals, so we redirect to home and show the modal)

    if (to.path === '/login' || to.path === '/signup') {
        next({
            name: 'home.index',
            replace: true
        });
        return;
    }



    // Permite la navegación normal
    next();
    CinelarTV.config.globalProperties.$progress.finish()
});



AppRouter.afterEach((to, from) => {
    if (window.MiniProfiler && from) {
        window.MiniProfiler.pageTransition();
    }
    document.body.setAttribute('data-current-path', to.path);
    CinelarTV.config.globalProperties.$progress.finish()
})


window.AppRouter = AppRouter

export default AppRouter;