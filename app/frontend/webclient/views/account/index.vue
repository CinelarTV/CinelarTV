<template>
    <div class="user-dashboard wrap">
        <div class="admin-main-nav">
            <ul class="nav nav-pills overflow-x-auto">
                <li v-for="link in userLinks" :key="link.to">
                    <router-link class="nav-item items-center min-w-0 whitespace-nowrap" :to="link.to"
                        active-class="admin-nav-active" :v-if="link.enabled === true">
                        <c-icon v-if="link.icon" :icon="link.icon" :size="20" class="icon"></c-icon>
                        {{ link.title }}
                    </router-link>
                </li>
            </ul>
        </div>
        <div class="user-dashboard-content mt-6">
            <RouterView />
        </div>
    </div>
</template>

<script setup>
import { inject, ref } from 'vue';
import { useHead } from 'unhead';

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');
const currentUser = inject('currentUser');

const userLinks = [
    {
        icon: 'layout-grid',
        title: i18n.t('js.user.nav.dashboard'),
        to: '/account/dashboard',
    },
    {
        icon: 'credit-card',
        title: i18n.t('js.user.nav.subscriptions'),
        to: '/account/billing',
        enabled: SiteSettings.enable_subscription || false, // Subscriptions tab is enabled only if subscriptions are enabled
    },
    {
        icon: 'settings',
        title: i18n.t('js.user.nav.settings'),
        to: '/account/settings',
    },
].filter((link) => link.enabled !== false);

useHead({
    title: 'Account',
    meta: [
        {
            name: 'description',
            content: 'Account',
        },
    ],
});



</script>
