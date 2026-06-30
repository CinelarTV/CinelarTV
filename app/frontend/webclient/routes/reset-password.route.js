let ResetPasswordRoute = {
    name: 'reset-password',
    path: '/reset-password',
    component: () => import(/* webpackChunkName: "auth" */ '../views/reset-password.tsx'),
}

export default ResetPasswordRoute
