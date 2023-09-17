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
import { inject } from 'vue';
import SiteHeader from './components/site-header.vue'
import { useHead } from 'unhead'
import { useRoute } from 'vue-router';
import SiteBanner from './components/site-banner.vue';
import OfflineIndicator from './components/offline-indicator.vue';
const route = useRoute();

const SiteSettings = inject('SiteSettings');

useHead({
    title: SiteSettings.site_name,
    titleTemplate: `%s | ${SiteSettings.site_name}`,
    meta: [
        {
            name: 'description',
            content: SiteSettings.value?.site?.description
        }
    ]
})
</script>