let LiveTvGuideRoute = {
    path: '/live_tv/:id/guide',
    name: 'live_tv.guide',
    component: () => import(/* webpackChunkName: "live-tv-guide" */ '../views/live-tv-guide.tsx'),
    meta: {
        transition: 'fade',
        requiresAuth: true
    }
};

export default LiveTvGuideRoute;
