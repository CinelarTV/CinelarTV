let LiveTvIndexRoute = {
    path: '/live_tv',
    name: 'live_tv.index',
    component: () => import(/* webpackChunkName: "live-tv-index" */ '../views/live-tv-index.tsx'),
    meta: {
        transition: 'fade',
        requiresAuth: true
    }
};

export default LiveTvIndexRoute;
