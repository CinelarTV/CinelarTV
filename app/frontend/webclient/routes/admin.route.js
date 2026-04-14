const AdminBase = () => import( /* webpackChunkName: "admin-base" */ '../views/admin/base.vue');
const AdminDashboard = () => import( /* webpackChunkName: "admin-dashboard" */ '../views/admin/dashboard.vue');
const AdminSettingsLayout = () => import('../views/admin/settings/base.vue');

import Updater from "../views/admin/updater.vue";


const AdminRoutes = {
    path: '/admin',
    redirect: '/admin/dashboard',
    component: AdminBase,
    children: [
        {
            name: 'admin.dashboard',
            path: 'dashboard',
            component: AdminDashboard,
            meta: {
                requireAdmin: true
            }
        },
        {
            name: 'admin.updates',
            path: 'updates',
            component: Updater,
            meta: {
                requireAdmin: true
            }
        },
        {
            name: 'admin.users',
            path: 'users',
            component: () => import('../views/admin/Users.tsx'),
            meta: {
                requireAdmin: true
            }
        },
        {
            name: 'admin.subscriptions',
            path: 'subscriptions',
            component: () => import('../views/admin/subscriptions.vue'),
            meta: {
                requireAdmin: true
            }
        },
        {
            name: 'admin.live_tv',
            path: 'live-tv',
            component: () => import('../views/admin/live-tv.vue'),
            meta: {
                requireAdmin: true
            }
        },
        {
            name: 'admin.customization.iconmap',
            path: 'icons',
            component: () => import('../views/admin/IconLibrary')
        },
        {
            name: 'admin.content.manager',
            path: '/admin/content-manager',
            redirect: '/admin/content-manager/all',
            component: () => import('../views/admin/content-manager/base.vue'),
            meta: {
                requireAdmin: true
            },
            children: [
                {
                    name: 'admin.content.manager.all',
                    path: 'all',
                    component: () => import('../views/admin/content-manager/index.vue'),
                    meta: {
                        requireAdmin: true
                    }
                },
                {
                    name: 'admin.content.manager.edit',
                    path: ':id/edit',
                    component: () => import('../views/admin/content-manager/edit.vue'),
                    meta: {
                        requireAdmin: true
                    }
                },
                {
                    name: 'admin.content.manager.manage-episodes',
                    path: ':contentId/seasons/:seasonId/episodes',
                    component: () => import('../views/admin/content-manager/episode-manager.vue'),
                    meta: {
                        requireAdmin: true
                    }
                },
                {
                    name: 'admin.content.manager.manage-episodes.edit',
                    path: ':contentId/seasons/:seasonId/episodes/:episodeId/edit',
                    component: () => import('../views/admin/content-manager/episodes/EditEpisode.tsx'),
                    meta: {
                        requireAdmin: true
                    }
                }
            ]
        },
        {
            name: 'admin.settings',
            path: 'settings',
            redirect: '/admin/site_settings',
            component: AdminSettingsLayout,
            meta: {
                requireAdmin: true
            },
            children: [
                {
                    name: 'admin.settings.general',
                    path: '/admin/site_settings',
                    component: () => import('../views/admin/settings/SettingsPanel.tsx'),
                    meta: {
                        requireAdmin: true
                    },
                    children: [
                        {
                            name: 'admin.settings.general.category',
                            path: ':category',
                            component: () => import('../views/admin/settings/SettingsPanel.tsx'),
                            meta: {
                                requireAdmin: true
                            }
                        }
                    ]
                },
            ]
        },
        {
            name: 'admin.webhooks',
            path: 'webhooks',
            children: [
                {
                    name: 'admin.webhooks.logs',
                    path: 'logs',
                    component: () => import('../views/admin/webhooks/logs.vue'),
                    meta: {
                        requireAdmin: true
                    }
                }
            ]
        }
    ],
    meta: {
        requireAdmin: true
    }
}

export default AdminRoutes