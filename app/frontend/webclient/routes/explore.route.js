import ExploreBrowse from '../views/ExploreBrowse.tsx'

let ExploreRoute = {
    name: 'explore.browse',
    path: '/explore/browse',
    component: ExploreBrowse,
    meta: {
        requiresAuth: true
    }
}

export default ExploreRoute
