<template>
    <div class="user-dashboard wrap">
        <div class="admin-nav">
            <div class="admin-nav__scroll">
                <router-link
                    v-for="link in userLinks"
                    :key="link.to"
                    class="admin-nav__item"
                    :to="link.to"
                    active-class="admin-nav__item--active"
                >
                    <CIcon v-if="link.icon" :icon="link.icon" :size="16" class="admin-nav__icon" />
                    <span class="admin-nav__label">{{ link.title }}</span>
                </router-link>
            </div>
        </div>
        <div class="user-dashboard-content mt-6">
            <RouterView />
        </div>
    </div>
</template>

<script setup>
import CIcon from "@/components/c-icon.vue"
import { inject } from 'vue'
import { useHead } from 'unhead'

const SiteSettings = inject('SiteSettings')
const i18n = inject('I18n')

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
        enabled: SiteSettings.enable_subscription || false,
    },
    {
        icon: 'settings',
        title: i18n.t('js.user.nav.settings'),
        to: '/account/settings',
    },
].filter((link) => link.enabled !== false)

useHead({
    title: 'Account',
    meta: [
        {
            name: 'description',
            content: 'Account',
        },
    ],
})
</script>
