<template>
    <div id="mountpoint">
        <vue3-progress id="c-progress" />
        <SiteHeader v-if="$route.meta.showHeader !== false" />
        <OfflineIndicator />
        <cinelar-main
            :class="{ 'with-header-offset': $route.meta.showHeader !== false, 'with-mobile-bottom-nav': showMobileBottomNav }">
            <SiteBanner />
            <router-view v-slot="{ Component, route }">
                <transition :name="route.meta.transition">
                    <component :is="Component" />
                </transition>
            </router-view>
        </cinelar-main>
        <MobileBottomNav v-if="showMobileBottomNav" />
        <Toaster theme="dark" />
    </div>
</template>

<script setup>
import SiteHeader from '@/components/SiteHeader.tsx'
import MobileBottomNav from '@/components/MobileBottomNav.tsx'
import { Toaster } from 'vue-sonner'
import 'vue-sonner/style.css'

import { useHead } from 'unhead'
import { useRoute } from 'vue-router';
import { computed } from 'vue';
import SiteBanner from './components/site-banner.vue';
import OfflineIndicator from './components/offline-indicator.vue';
import { useSiteSettings } from '@/app/services/site-settings.ts';
const route = useRoute();
const showMobileBottomNav = computed(() => {
    if (route.meta?.showMobileBottomNav === false) return false;

    const path = route.path || '';
    if (path.startsWith('/watch/')) return false;
    if (path.startsWith('/live/')) return false;

    if (route.meta?.showHeader === false && !path.startsWith('/live_tv')) return false;

    return true;
});

const { siteSettings } = useSiteSettings();
useHead({
    // @ts-ignore
    title: siteSettings.site_name,
    titleTemplate: `%s | ${siteSettings.site_name}`,
    meta: [
        {
            name: 'description',
            // @ts-ignore
            content: siteSettings.site_description
        }
    ]
})
</script>