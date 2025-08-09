let VideoPlayerRoute =
{
    path: '/watch/:id',
    name: 'videoplayer.show',
    component: () => import(/* webpackChunkName: "videoplayer" */ '../views/videoplayer.tsx'),
    meta: {
        transition: 'slide-fade',
        requiresAuth: true,
        showHeader: false
    },
    children: [
        {
            name: 'videoplayer.episode', // Cambiado para evitar duplicidad
            path: ':episodeId',
            component: () => import(/* webpackChunkName: "videoplayer" */ '../views/videoplayer.tsx'),
        },
    ]

}



export default VideoPlayerRoute