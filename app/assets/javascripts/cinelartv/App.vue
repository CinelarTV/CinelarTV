<template>
    <div id="mountpoint">
        <vue3-progress id="c-progress" />
        <SiteHeader v-if="$route.meta.showHeader !== false" />
        <plugin-outlet name="below-site-header" />
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
</script>