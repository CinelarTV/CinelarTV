
let AccountRoute = {
    name: 'account',
    path: '/account',
    component: () => import(/* webpackChunkName: "account" */ '../views/account/index.vue'),
    children: [
        {
            name: 'account.dashboard',
            path: 'dashboard',
            component: () => import(/* webpackChunkName: "account" */ '../views/account/dashboard.vue'),
            meta: {
                requireAuth: true
            }
        },
        {
            name: 'account.billing',
            path: 'billing',
            component: () => import(/* webpackChunkName: "account" */ '../views/account/billing.vue'),
            meta: {
                requireAuth: true
            }
        },
        {
            name: 'account.catchall',
            path: ':pathMatch(.*)*',
            component: () => import(/* webpackChunkName: "account" */ '../views/account/not-found.vue'),
            meta: {
                requireAuth: true
            }
        }
    ]
}

export default AccountRoute