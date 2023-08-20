<template>
    <div id="mountpoint">

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