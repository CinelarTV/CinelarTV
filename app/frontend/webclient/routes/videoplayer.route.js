let VideoPlayerRoute = {
    path: '/watch/:contentId/:episodeId?',
    name: 'videoplayer.show',
    component: () => import(/* webpackChunkName: "videoplayer" */ '../views/videoplayer.tsx'),
    meta: {
        transition: 'fade',
        requiresAuth: true,
        showHeader: false,
        forceRemount: true
    }
}

export default VideoPlayerRoute