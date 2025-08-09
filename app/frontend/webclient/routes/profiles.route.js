let ProfilesRouter =
{
    path: '/profiles',
    children: [
        {
            name: 'profile.select',
            path: '/profiles/select',
            component: () => import('../views/profiles/ProfileSelect.tsx'),
            meta: {
                requiresAuth: true,
                showHeader: false
            }
        },
    ]
}



export default ProfilesRouter