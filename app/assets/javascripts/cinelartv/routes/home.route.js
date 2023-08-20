import Home from'../views/home-explore.vue'

let HomeRoute = {
    name: 'home.index',
    path: '/',
    alias: '/home',
    component: Home,
    meta: {
        requiresAuth: true,
    }
 }

 
 export default HomeRoute