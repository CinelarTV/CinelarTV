let ProfilesRouter =
{
    path: '/profiles',
    children: [
        {
            name: 'profile.select',
            path: '/profiles/select',
            component: () => import('../views/profiles/profile-select.vue'),
            meta: {
                requiresAuth: true,
                showHeader: false
            }
        },
    ]
}



export default ProfilesRouter