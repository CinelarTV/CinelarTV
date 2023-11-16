<template>
    <div id="mountpoint">
        <vue3-progress id="c-progress" />
        <SiteHeader v-if="$route.meta.showHeader !== false" />
        <OfflineIndicator />
        <main>
            <SiteBanner />
            <router-view v-slot="{ Component, route }">
                <transition :name="route.meta.transition">
                    <component :is="Component" />
                </transition>
            </router-view>
        </main>
    </div>
</template>

<script setup>
import SiteHeader from './components/site-header.vue'
import { useHead } from 'unhead'
import { useRoute } from 'vue-router';
import SiteBanner from './components/site-banner.vue';
import OfflineIndicator from './components/offline-indicator.vue';
import { useSiteSettings } from './app/services/site-settings';
const route = useRoute();

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