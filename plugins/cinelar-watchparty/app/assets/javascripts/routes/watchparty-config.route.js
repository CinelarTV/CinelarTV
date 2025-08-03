export default {
    path: '/watchparty', // Asegúrate de que cada ruta tenga una propiedad path
    name: 'watchparty.index',
    component: () => import(/* webpackChunkName: "watchparty" */ '../views/introducing-watchparty.vue'),
    meta: {
        requiresAuth: true,
        title: 'Watch Party'
    }
}
