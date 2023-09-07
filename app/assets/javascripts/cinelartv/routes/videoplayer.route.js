let VideoPlayerRoute =
{
    path: '/watch/:id',
    name: 'videoplayer.show',
    component: () => import(/* webpackChunkName: "videoplayer" */ '../views/videoplayer.vue'),
    meta: {
        transition: 'slide-fade',
        requiresAuth: true,
        showHeader: false
    },
    children: [
        {
            name: 'videoplayer.show',
            path: ':episodeId'
        }
    ]
    
}



export default VideoPlayerRoute