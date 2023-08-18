import { createWebHistory, createRouter } from 'vue-router'
import { currentUser, SiteSettings } from '../pre-initializers/essentials-preload'

function loadRoutes() {
    const routes = require.context('./', true, /\.route\.js$/)
    return routes.keys()
      .map(routes)         // import module
      .map(m => m.default)  // get `default` export from each resolved module
  }
  
let routes = loadRoutes()
  
  
  
const AppRouter = createRouter({
      history: createWebHistory(),
      routes
  });
  

AppRouter.beforeEach((to, from, next) => {

   

    if (to.meta.requiresAuth && !currentUser) {
        next({
            name: 'NotFound',
            params: [to.path],
            replace: true
        })

    }

    else if (to.meta.requireAdmin && !currentUser.is_admin || false) {
        next({
            name: 'NotFound',
            params: [to.path],
            replace: true
        })

    }
    else next() 
})

AppRouter.afterEach((to, from) => {
    if (window.MiniProfiler && from) {
        window.MiniProfiler.pageTransition();
    }
    document.body.setAttribute('data-current-path', to.path);
})


window.AppRouter = AppRouter

export default AppRouter;