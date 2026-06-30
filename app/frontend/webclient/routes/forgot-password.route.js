let ForgotPasswordRoute = {
    name: 'forgot-password',
    path: '/forgot-password',
    component: () => import(/* webpackChunkName: "auth" */ '../views/forgot-password.tsx'),
}

export default ForgotPasswordRoute
