let LiveTvPlayerRoute = {
    path: '/live/:id',
    name: 'live_tv.watch',
    component: () => import(/* webpackChunkName: "live-tv-player" */ '../views/live-tv-player.tsx'),
    meta: {
        transition: 'fade',
        requiresAuth: true,
        showHeader: false
    }
};

export default LiveTvPlayerRoute;
