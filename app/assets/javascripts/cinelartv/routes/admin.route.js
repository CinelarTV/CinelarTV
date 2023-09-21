const AdminBase = () => import( /* webpackChunkName: "admin-base" */ '../views/admin/base.vue');
const AdminDashboard = () => import( /* webpackChunkName: "admin-dashboard" */ '../views/admin/dashboard.vue');
const AdminSettingsLayout = () => import('../views/admin/settings/base.vue');

import SettingsView from '../views/admin/settings/index.vue';

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
            component: () => import('../views/admin/users.vue'),
            meta: {
                requireAdmin: true
            }
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
                    component: SettingsView,
                    meta: {
                        requireAdmin: true
                    },
                    children: [
                        {
                            name: 'admin.settings.general.category',
                            path: ':category',
                            component: SettingsView,
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