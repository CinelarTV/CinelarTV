
let ContentRoute = {
    name: 'content.show',
    path: '/contents/:id',
    component: () => import(/* webpackChunkName: "content" */ '../views/content.vue'),
    meta: {
        transition: 'slide-fade',
    }
 }

 
 export default ContentRoute