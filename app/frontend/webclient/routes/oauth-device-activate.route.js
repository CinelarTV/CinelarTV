let OauthDeviceActivateRoute = {
    name: 'oauth.device.activate',
    path: '/oauth/device',
    component: () => import(/* webpackChunkName: "oauth-device-activate" */ '../views/oauth-device-activate.tsx')
}

export default OauthDeviceActivateRoute
