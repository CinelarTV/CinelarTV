export default {
    path: '/', // Asegúrate de que cada ruta tenga una propiedad path
    name: 'home.index',
    component: () => import(/* webpackChunkName: "watchparty" */ '../views/introducing-watchparty.vue'),
    meta: {
        requiresAuth: true,
        title: 'Watch Party'
    }
}
