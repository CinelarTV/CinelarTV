
let ContentRoute = {
    name: 'content.show',
    path: '/contents/:id',
    component: () => import(/* webpackChunkName: "content" */ '../views/Content.tsx'),
    meta: {
        transition: 'fade',
    }
}


export default ContentRoute