
let ContentRoute = {
    name: 'content.show',
    path: '/contents/:id',
    component: () => import(/* webpackChunkName: "content" */ '../views/content.vue'),
 }

 
 export default ContentRoute