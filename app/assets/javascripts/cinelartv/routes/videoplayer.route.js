let VideoPlayerRoute =
{
    path: '/watch/:id',
    name: 'videoplayer.show',
    component: () => import(/* webpackChunkName: "videoplayer" */ '../views/videoplayer.vue'),
    meta: {
        transition: 'slide-fade',
        requiresAuth: true,
        showHeader: false
    }
    
}



export default VideoPlayerRoute