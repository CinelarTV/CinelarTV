
let NotFoundRoute = {
    name: 'application.not-found',
    path: '/:pathMatch(.*)*',
    component: () => import(/* webpackChunkName: "not-found" */ '../views/errors/not-found.vue'),
}



export default NotFoundRoute

