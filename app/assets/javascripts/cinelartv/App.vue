<template>
    <div id="mountpoint">
        <vue3-progress id="c-progress" />
        <SiteHeader v-if="$route.meta.showHeader !== false" />
        <main>
            <SiteBanner />
            <router-view />
        </main>
    </div>
</template>

<script setup>
    import SiteHeader from './components/site-header.vue'
</script>